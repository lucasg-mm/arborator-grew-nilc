from datetime import datetime

"""
Module to deal with validation of various types of 
data.
"""


def validate_date_range(from_date, to_date):
    """
    --DESCRIPTION:
    Validates a date range of [from_date, to_date] 

    --PARAMETERS:
    from_date: lower bound.
    to_date: upper bound.

    --RETURNS:
    Boolean indicating whether the date range is 
    valid or no.
    """

    # parse the strings to datetime objects
    lower_datetime = datetime.strptime(from_date, "%d-%m-%Y")
    upper_datetime = datetime.strptime(to_date, "%d-%m-%Y")

    # returns the result of comparison (a boolean)
    return lower_datetime <= upper_datetime


def validate_date_format(date_text):
    """
    --DESCRIPTION:
    Validates 'date_text', telling whether if it is
    in the "DD-MM-YYYY" format. 

    --PARAMETERS:
    date_text: string representing a date.

    --RETURNS:
    Boolean indicating whether the date format in date_text is 
    valid or no.
    """

    try:
        datetime.strptime(date_text, '%d-%m-%Y')
    except ValueError:
        # validation failed!
        return False
    # validation was successful
    return True
