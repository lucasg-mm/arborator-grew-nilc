from authomatic.providers import oauth2

CONFIG = {
    "google": {
        # Google's credentials
        "class_": oauth2.Google,
        "consumer_key": '133171478313-o18120v337b4onv9g3u16i6kdg1042kr.apps.googleusercontent.com',
        "consumer_secret": 'yiK0iLPBZAF_kd5ZKlY5p9di',
        "scope": ["email", "profile", "openid"]
    },
    "github": {
        # GitHub's credentials
        "class_": oauth2.GitHub,
        "consumer_key": '17a17e32a27a3b34d22c',
        "consumer_secret": '92c8221315845d26c1dce36fcf8fe68becc385b7',
        "scope": ["user"]
    }
}
