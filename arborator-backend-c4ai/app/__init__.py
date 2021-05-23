from flask import Flask, jsonify, send_from_directory
from flask_sqlalchemy import SQLAlchemy
from flask_restx import Api

from flask_login import LoginManager, current_user
from flask_migrate import Migrate

from app.klang.config import KlangConfig
from app.utils.grew_config import GrewConfig

from flask_cors import CORS

db = SQLAlchemy()
login_manager = LoginManager()
migrate = Migrate()

klang_config = KlangConfig()
grew_config = GrewConfig()


def create_app(env=None):
    from app.config import config_by_name
    from app.routes import register_routes
    app_env = env or "test"
    app = Flask(__name__, instance_relative_config=False)
    CORS(app, supports_credentials=True)  # enables CORS!
    app.config.from_object(config_by_name[env or "test"])
    klang_config.set_path(env or "test")
    grew_config.set_url(env or "test")

    api = Api(
        app,
        title="Arborator-Grew Backend",
        version="0.1.0",
        doc="/api/doc",
        endpoint="/api",
        base_url="/api",
    )

    register_routes(api, app)
    db.init_app(app)
    migrate.init_app(app, db)

    from .auth import auth as auth_blueprint

    app.register_blueprint(auth_blueprint, url_prefix="/")

    @app.route("/health")
    def health():
        return jsonify("healthy")

    # service for mp3 file, which will be taken from app/public folder
    @app.route('/media/<path:path>')
    def media(path):
        return send_from_directory('public', path)

    login_manager.init_app(app)

    return app
