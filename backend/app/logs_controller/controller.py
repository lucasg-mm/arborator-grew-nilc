from datetime import datetime
from flask_restx import Namespace, Resource
from flask_restful import abort
from flask import Response, request, jsonify
from app.utils.log_manager import get_zipped_log_files
from app.utils.validators import validate_date_format, validate_date_range

api = Namespace(
    "Samples", description="Endpoint to recover the file's logs"
)


@api.route("/<string:project_name>/logs/export")
class ExportLogsResource(Resource):
    def post(self, project_name: str):

        # parse the client's request to JSON
        time_window = request.get_json(force=True)

        # gets the time window to recover the logs
        initial_date = time_window["from"]
        final_date = time_window["to"]

        # validates the dates formats
        if not validate_date_format(initial_date) or not validate_date_format(final_date):
            abort(400, error_message="Invalid date format!")

        # validates the date range
        if not validate_date_range(initial_date, final_date):
            abort(400, error_message="Invalid date range!")

        # gets the .zip with the relevant log files
        logs_byte_buffer = get_zipped_log_files(
            project_name, initial_date, final_date)

        # validates the return value of 'logs_byte_buffer'
        if not logs_byte_buffer:
            abort(404, error_message="No log was found in the specified time range!")

        # sends the successful response
        resp = Response(
            logs_byte_buffer,
            status=200,
            mimetype="application/zip",
            headers={
                "Content-Disposition": "attachment;filename=logs.{}.zip".format(
                    project_name
                )
            },
        )
        return resp
