class GrewConfig:
    def __init__(self):
        self.server = None

    def set_url(self, env):
        if env == "prod":
            self.server = "http://localhost:3000"
        else:  # if env is dev or test
            self.server = "http://localhost:3000"
