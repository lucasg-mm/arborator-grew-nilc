from datetime import datetime
from os import path, makedirs
import pathlib

# the constant below holds the path to the logs directory
LOG_DIRECTORY = f"{pathlib.Path(__file__).parent.absolute()}/../logs"


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
