from datetime import datetime
from os import path, mkdir
import pathlib

# the constant below holds the path to the logs directory
LOG_DIRECTORY = f"{pathlib.Path(__file__).parent.absolute()}/../logs"

# key-value pairs where:
# key is a string with the username
# value is the current active log file
# these are just for online users!
ONLINE_USERS_LOG = {}


def write_login(username):
    """
    -- Description:
    Notes the login of a certain user in this user's.
    log file.
    -- Parameters:
    username - A string with the username of the user
    who logged in.
    """

    # get the directory where all the user's logs
    # should be
    user_log_directory = f"{LOG_DIRECTORY}/{username}"

    # checks if the this directory already exists
    if not path.isdir(user_log_directory):
        # if it doesn't, creates it (logs, inside app)
        mkdir(user_log_directory)

    # gets a timestamp for the login
    timestamp_str = datetime.now().strftime("%d-%m-%Y %H:%M:%S")

    # saves the path to the active log file of this user
    # in the dictionary
    ONLINE_USERS_LOG[username] = f"{user_log_directory}/{timestamp_str}.txt"

    # writes the login occurrence in the log file
    with open(ONLINE_USERS_LOG[username], "a") as log_file:
        log_file.write(f"({timestamp_str}) Logged in\n\n")

    return


def write_save(username, project_name, sentence_id, list_of_changes):
    """
    -- Description:
    Tracks saves of a user in a sentence of a certain project.
    It also tracks the changes made in this save.
    -- Parameters:
    username - Username of the user who requested the save. 
    project_name - Name of the project which the saved sentence is from.
    sentence_id - Id of the saved sentence.
    list_of_changes - List of strings describing the changes commited in the
                      save.
    """

    # gets the timestamp for the save
    timestamp_str = datetime.now().strftime("%d-%m-%Y %H:%M:%S")

    # writes the save in the user's current log file
    with open(ONLINE_USERS_LOG[username], "a") as log_file:
        # tracks where the save was made
        log_file.write(
            f"({timestamp_str}) Saved the following changes in the sentence of id \"{sentence_id}\", project \"{project_name}\":\n")

        # tracks the changes made in the save
        if not list_of_changes:
            log_file.write("   - No changes were made in this save\n")
        else:
            for change in list_of_changes:
                log_file.write(f"   - {change}\n")

        # skips a line
        log_file.write("\n")

    return


def write_logout(username):
    """
    -- Description:
    Tracks the logout of a certain user in this user's current log file
    log file.
    -- Parameters:
    username - A string with the username of the user
    who logged out.
    """

    # gets a timestamp for the logout
    timestamp_str = datetime.now().strftime("%d-%m-%Y %H:%M:%S")

    # writes the login occurrence in the log file
    with open(ONLINE_USERS_LOG[username], "a") as log_file:
        log_file.write(f"({timestamp_str}) Logged out\n\n")

    # deletes the user's pair in the active
    # logs dict
    ONLINE_USERS_LOG.pop(username, None)

    return
