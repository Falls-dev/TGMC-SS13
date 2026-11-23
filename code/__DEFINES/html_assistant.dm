#define HTML_SKELETON_INTERNAL(head, body) \
"<!DOCTYPE html><html><head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'><meta http-equiv='X-UA-Compatible' content='IE=edge'>[head]</head><body>[body]</body></html>"

#define HTML_TITLE(title) "<title>[html_encode(html_decode("[title]"))]</title>"
#define HTML_SKELETON_TITLE(title, body) HTML_SKELETON_INTERNAL(HTML_TITLE(title), body)
#define HTML_SKELETON(body) HTML_SKELETON_INTERNAL("", body)

// Static documents can display paper formatting and asset images without active content.
#define HTML_STATIC_CONTENT_POLICY_INTERNAL(directives) {"<meta http-equiv="Content-Security-Policy" content="script-src 'none'; object-src 'none'; frame-src 'none'; base-uri 'none'; [directives]">"}
#define HTML_STATIC_CONTENT_POLICY HTML_STATIC_CONTENT_POLICY_INTERNAL("form-action 'none'")
#define HTML_TEXT_CONTENT_POLICY HTML_STATIC_CONTENT_POLICY_INTERNAL("form-action 'none'; img-src 'none'")
#define HTML_FORM_CONTENT_POLICY HTML_STATIC_CONTENT_POLICY_INTERNAL("img-src 'none'")
#define HTML_STATIC_SKELETON_TITLE(title, body) HTML_SKELETON_INTERNAL(HTML_STATIC_CONTENT_POLICY + HTML_TITLE(title), body)
