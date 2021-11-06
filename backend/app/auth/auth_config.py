import os
from authomatic.providers import oauth2
from dotenv import load_dotenv
load_dotenv(dotenv_path="../../.flaskenv", verbose=True)

CONFIG = {
    "google": {
        # Google's credentials
        "class_": oauth2.Google,
        "consumer_key": os.getenv("GOOGLE_KEY"),
        "consumer_secret": os.getenv("GOOGLE_SECRET"),
        "scope": ["email", "profile", "openid"]
    },
    "github": {
        # GitHub's credentials
        "class_": oauth2.GitHub,
        "consumer_key": os.getenv("GITHUB_KEY"),
        "consumer_secret": os.getenv("GITHUB_SECRET"),
        "scope": ["user"]
    },
    "facebook": {
        # Facebook's credentials
        "class_": oauth2.Facebook,
        "consumer_key": os.getenv("FACEBOOK_KEY"),
        "consumer_secret": os.getenv("FACEBOOK_SECRET"),
        "scope": ["email", "public_profile"]
    },
    "windows_live": {
        # Microsoft's credentials
        "class_": oauth2.WindowsLive,
        "consumer_key": os.getenv("MICROSOFT_KEY"),
        "consumer_secret": os.getenv("MICROSOFT_SECRET"),
        "scope": ["https://graph.microsoft.com/User.Read"]
    }
}
