import os
import io
import json
import gc
import random
import torch
import soundfile as sf
from flask import Flask, request, send_file, abort
from pydub import AudioSegment
from pydub.silence import split_on_silence

app = Flask(__name__)
os.makedirs('samples', exist_ok=True)

LANGUAGE = 'ru'
SPEAKER_MODEL = 'v5_5_ru'
SAMPLE_RATE = 48000
DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

current_dir = os.path.dirname(os.path.abspath(__file__))
models_dir = os.environ.get('TTS_HOME', os.path.join(current_dir, 'tts_data'))
os.makedirs(models_dir, exist_ok=True)
torch.hub.set_dir(models_dir)

print(f"Loading Silero TTS on {DEVICE}...")
print(f"Model cache directory: {models_dir}")

model, _ = torch.hub.load(repo_or_dir='snakers4/silero-models',
						  model='silero_tts',
						  language=LANGUAGE,
						  speaker=SPEAKER_MODEL,
						  trust_repo=True)
model.to(DEVICE)

SILERO_VOICES = ["aidar", "baya", "kseniya", "xenia", "eugene", "random"]

letters_to_use = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ1234567890"
random_factor = 0.35
request_count = 0

voice_name_mapping = {}
use_voice_name_mapping = True

if os.path.exists("./tts_voices_mapping.json"):
	with open("./tts_voices_mapping.json", "r", encoding="utf-8") as file:
		voice_name_mapping = json.load(file)
		if len(voice_name_mapping) == 0:
			use_voice_name_mapping = False
else:
	use_voice_name_mapping = False

voice_name_mapping_reversed = {v: k for k, v in voice_name_mapping.items()}

def get_request_data():
	text = ""
	voice = "random"

	if request.is_json:
		text = request.json.get("text", "")
		voice = request.json.get("voice", request.args.get("voice", "xenia"))
	else:
		text = request.args.get("text", "")
		voice = request.args.get("voice", "xenia")

	if use_voice_name_mapping and voice in voice_name_mapping_reversed:
		voice = voice_name_mapping_reversed[voice]

	if voice not in SILERO_VOICES:
		voice = "random"

	return text, voice

@app.route("/tts", methods=['GET', 'POST'])
@app.route("/generate-tts", methods=['GET', 'POST'])
def text_to_speech():
	global request_count
	text, voice = get_request_data()

	if not text:
		return "No text provided", 400

	try:
		with torch.no_grad():
			audio = model.apply_tts(text=text, speaker=voice, sample_rate=SAMPLE_RATE)

		buffer = io.BytesIO()

		audio_numpy = audio.squeeze().cpu().numpy()
		sf.write(buffer, audio_numpy, SAMPLE_RATE, format='WAV')

		buffer.seek(0)

		request_count += 1
		return send_file(buffer, mimetype="audio/wav")
	except Exception as e:
		print(f"TTS Error: {e}")
		return str(e), 500

@app.route("/tts-blips", methods=['GET', 'POST'])
@app.route("/generate-tts-blips", methods=['GET', 'POST'])
def text_to_speech_blips():
	global request_count
	text, voice = get_request_data()
	text = text.upper()

	if not text:
		return "No text provided", 400

	try:
		voice_dir = f"samples/{voice}"
		os.makedirs(voice_dir, exist_ok=True)

		with torch.no_grad():
			for value in letters_to_use:
				letter_path = f"{voice_dir}/{value}.wav"
				if not os.path.exists(letter_path):
					try:
						audio = model.apply_tts(text=value + ".", speaker=voice, sample_rate=SAMPLE_RATE)
						temp_buffer = io.BytesIO()

						audio_numpy = audio.squeeze().cpu().numpy()
						sf.write(temp_buffer, audio_numpy, SAMPLE_RATE, format='WAV')

						temp_buffer.seek(0)

						loaded_word = AudioSegment.from_file(temp_buffer)
						audio_chunks = split_on_silence(loaded_word, min_silence_len=100, silence_thresh=-45, keep_silence=50)

						combined = AudioSegment.empty()
						for chunk in audio_chunks:
							combined += chunk

						if len(combined) == 0:
							combined = loaded_word

						combined.export(letter_path, format='wav')
					except Exception as e:
						print(f"Blip generation warning for {value}: {e}")
						pass

		result_sound = None
		for i, letter in enumerate(text):
			if not letter.isalpha() or letter.isnumeric():
				continue

			if letter == ' ':
				new_sound = AudioSegment.silent(duration=50, frame_rate=22050)
			else:
				if i % 2 != 0:
					continue

				letter_path = f"{voice_dir}/{letter}.wav"
				if not os.path.isfile(letter_path):
					continue

				letter_sound = AudioSegment.from_file(letter_path)

				if len(letter_sound.raw_data) > 5000:
					raw = letter_sound.raw_data[2500:-2500]
				else:
					raw = letter_sound.raw_data

				octaves = 1 + random.random() * random_factor
				frame_rate = int(letter_sound.frame_rate * (2.0 ** octaves))

				new_sound = letter_sound._spawn(raw, overrides={'frame_rate': frame_rate})
				new_sound = new_sound.set_frame_rate(22050)

			result_sound = new_sound if result_sound is None else result_sound + new_sound

		if result_sound is None:
			return "Failed to generate blips", 500

		out_buffer = io.BytesIO()
		result_sound.export(out_buffer, format='wav')
		out_buffer.seek(0)

		request_count += 1
		return send_file(out_buffer, mimetype="audio/wav")
	except Exception as e:
		print(f"Blips Error: {e}")
		return str(e), 500

@app.route("/tts-voices", methods=['GET'])
def voices_list():
	if use_voice_name_mapping:
		data = list(voice_name_mapping.values())
		data.sort()
		return json.dumps(data)
	else:
		return json.dumps(SILERO_VOICES)

@app.route("/health-check", methods=['GET'])
def tts_health_check():
	gc.collect()
	if request_count > 2048:
		return f"EXPIRED: {request_count}", 500
	return f"OK: {request_count}", 200

@app.route("/pitch-available", methods=['GET'])
def pitch_available():
	abort(500)

if __name__ == "__main__":
	if os.getenv('TTS_LD_LIBRARY_PATH', "") != "":
		os.environ['LD_LIBRARY_PATH'] = os.getenv('TTS_LD_LIBRARY_PATH')

	from waitress import serve
	print("TTS Server started on port 5003")
	serve(app, host="0.0.0.0", port=5003, threads=4, backlog=8, connection_limit=24, channel_timeout=10)
