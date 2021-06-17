from datetime import datetime
from os import path, makedirs, walk
from shutil import rmtree
from io import BytesIO
from zipfile import ZipFile, ZIP_DEFLATED
from re import findall
import pathlib

# the constant below holds the path to the logs directory
LOG_DIRECTORY = f"{pathlib.Path(__file__).parent.absolute()}/../logs"


def get_log_file_paths(project_name, initial_date, final_date):
    """
    --DESCRIPTION:
    Gets the log files paths for the given project in the given 
    time window.

    --PARAMETERS:
    initial_date: inferior limit for the time window (inclusive).
    final_date: superior limit for the time window (inclusive).

    --RETURNS:
    A 3-tuple (filepath, filename, username). Such that "filepath" is
    the path of the log file, "filename" is it's name, and "username"
    is the username of the log file's owner. 
    """

    # gets the dates passed as parameters in datetime format
    initial_date = datetime.strptime(initial_date, "%d-%m-%Y")
    final_date = datetime.strptime(final_date, "%d-%m-%Y")

    # initializing empty file paths list
    file_paths = []

    # gets the directory where the project's logs are located
    project_logs_directory = f"{LOG_DIRECTORY}/{project_name}"

    # crawling through directory and subdirectories
    for root, _, files in walk(project_logs_directory):
        # gets the username from the root directory
        username = findall(r"/([^/]+)\Z", root)[0]

        for filename in files:
            # gets the file's creation date from the name
            created_file_date = filename[:-4]

            # converts the date to an actual datetime object
            created_file_date = datetime.strptime(
                created_file_date, "%d-%m-%Y")

            # just returns the path to the file if it's between the specified
            # time window
            if created_file_date >= initial_date and created_file_date <= final_date:
                # join the two strings in order to form the full filepath.
                filepath = path.join(root, filename)
                file_paths.append((filepath, filename, username))

    # returning all file paths
    return file_paths


def get_zipped_log_files(project_name, initial_date, final_date):
    """
    --DESCRIPTION:
    Handles the download of log files.

    --PARAMETERS:
    initial_date: inferior limitant date.
    final_date: superior limitant date.

    --RETURNS:
    - byte buffer with the zip file with the log files in the 
    specified time window
    or
    - None if there is no log file in the specified time window.
    """

    # gets the logs for the given project in the given time window
    log_file_paths = get_log_file_paths(project_name, initial_date, final_date)

    # continues only if the list is not empty. Else, returns None
    if log_file_paths:
        # initializes byte buffer to write the contents of the .zip file
        zip_byte_buffer = BytesIO()

        # writes the contents on the 'zip_as_bytes' buffer
        with ZipFile(zip_byte_buffer, "w") as zip_file:
            for path, file_name, user in log_file_paths:
                zip_file.write(path, f"{user}\\{file_name}", ZIP_DEFLATED)

        # returns the byte buffer
        return zip_byte_buffer


def delete_project_folder(project_name):
    """
    --DESCRIPTION:
    Deletes the project folder inside the logs directory.

    --PARAMETERS:
    project_name: name of the project to which the folder
    refers.
    """

    # deletes the folder and everything inside it
    rmtree(f"{LOG_DIRECTORY}/{project_name}")

    return


def get_file_directory(project_name, username):
    """
    --DESCRIPTION:
    Gets the relative path to the file representing
    the current day.

    --PARAMETERS:
    project_name: name of the project the file is from.
    username: username of the user who is triggering the save.
    """

    # gets the date the file should represent
    date = datetime.now().strftime("%d-%m-%Y")

    # gets the directory to the users logs inside this project
    user_log_directory = f"{LOG_DIRECTORY}/{project_name}/{username}"

    # checks if this directory already exists
    if not path.isdir(user_log_directory):
        # if it doesn't, creates it (logs, inside app)
        makedirs(user_log_directory)

    # returns the path
    return f"{user_log_directory}/{date}.txt"


def write_save(username, project_name, sentence_id, list_of_changes):
    """
    -- DESCRIPTION:
    Tracks saves of a user in a sentence of a certain project.
    It also tracks the changes made in this save.

    -- PARAMETERS:
    username - Username of the user who requested the save.
    project_name - Name of the project which the saved sentence is from.
    sentence_id - Id of the saved sentence.
    list_of_changes - List of strings describing the changes commited in the
                      save.
    """

    # gets the file directory of the current active file
    file_directory = get_file_directory(project_name, username)

    # gets the time of the save
    time = datetime.now().strftime("%H:%M:%S")

    # writes the save in the user's current log file
    with open(file_directory, "a") as log_file:
        # tracks where the save was made
        log_file.write(
            f"({time}) Saved the following changes in the sentence of id \"{sentence_id}\":\n")

        # tracks the changes made in the save
        if not list_of_changes:
            log_file.write("   - No changes were made in this save\n")
        else:
            for change in list_of_changes:
                log_file.write(f"   - {change}\n")

        # skips a line
        log_file.write("\n")

    return
