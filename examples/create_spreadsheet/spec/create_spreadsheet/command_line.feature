Feature: CreateSpreadsheet::Cli#parse

Parse the create-spreadsheet command line

  Example: Nothing is given on the command line
    Given the command line ""
    When the command line is parsed
    Then the parser should have succeeded
    And the title attribute should be nil
    And the sheets attribute should be empty
    And the permissions attribute should be empty
    And the folder_id attribute should be nil

  Example: A spreadsheet title is given
    Given the command line "MySpreadsheet"
    When the command line is parsed
    Then the parser should have succeeded
    And the title attribute should be "MySpreadsheet"

  Example: A sheet is defined with a title
    Given the command line "--sheet=Summary"
    When the command line is parsed
    Then the parser should have succeeded
    And the sheets attribute should contain the following Sheets:
      """
        [
          {
            title: "Summary",
            data: nil
          }
        ]
      """

  Example: A sheet is defined with a title and data
    Given the command line "--sheet=Summary --data=data1.csv"
    And a file "data1.csv" containing:
      """
      1,2,3
      4,5,6
      """
    When the command line is parsed
    Then the parser should have succeeded
    And the sheets attribute should contain the following Sheets:
      """
        [
          {
            "title": "Summary",
            "data": [["1", "2", "3"], ["4", "5", "6"]]
          }
        ]
      """

  Example: Multiple sheets are defined both with data
    Given the command line "--sheet=Summary --data=summary.csv --sheet=Detail --data=detail.csv"
    And a file "summary.csv" containing:
      """
      6
      """
    And a file "detail.csv" containing:
      """
      1
      2
      3
      """
    When the command line is parsed
    Then the parser should have succeeded
    And the sheets attribute should contain the following Sheets:
      """
      [
        { "title": "Summary", "data": [["6"]] },
        { "title": "Detail", "data": [["1"], ["2"], ["3"]] }
      ]
      """

  Example: Multiple sheets are defined only one with data
    Given the command line "--sheet=Summary --sheet=Detail --data=detail.csv"
    And a file "detail.csv" containing:
      """
      Name,Age
      John,25
      Jane,23
      """
    When the command line is parsed
    Then the parser should have succeeded
    And the sheets attribute should contain the following Sheets:
      """
      [
        { title: "Summary", data: nil },
        { title: "Detail", data: [["Name", "Age"], ["John", "25"], ["Jane", "23"]] }
      ]
      """

  Example: A user permission is given
    Given the command line "--permission=user:bob@example.com:reader"
    When the command line is parsed
    Then the parser should have succeeded
    And the permissions attribute should contain the following Permissions:
      """
      [
        {
          "permission_spec": "user:bob@example.com:reader",
          "type": "user", "subject": "bob@example.com", "role": "reader"
        }
      ]
      """

  Example: A group permission is given
    Given the command line "--permission=group:admins@example.com:writer"

    When the command line is parsed
    Then the parser should have succeeded
    And the permissions attribute should contain the following Permissions:
      """
      [
        {
          "permission_spec": "group:admins@example.com:writer",
          "type": "group", "subject": "admins@example.com", "role": "writer"
        }
      ]
      """

  Example: A domain permission is given
    Given the command line "--permission=domain:domain_name:reader"
    When the command line is parsed
    Then the parser should have succeeded
    And the permissions attribute should contain the following Permissions:
      """
      [
        {
          "permission_spec": "domain:domain_name:reader",
          "type": "domain", "subject": "domain_name", "role": "reader"
        }
      ]
      """

  Example: An anyone permission is given
    Given the command line "--permission=anyone:reader"
    When the command line is parsed
    Then the parser should have succeeded
    And the permissions attribute should contain the following Permissions:
      """
      [
        {
          permission_spec: "anyone:reader", type: "anyone", subject: nil, role: "reader"
        }
      ]
      """

  Example: Multiple permissions are given
    Given the command line "--permission=user:bob@example.com:writer --permission=anyone:reader"
    When the command line is parsed
    Then the parser should have succeeded
    And the permissions attribute should contain the following Permissions:
      """
      [
        {
          permission_spec: "user:bob@example.com:writer", type: "user", subject: "bob@example.com", role: "writer"
        },
        {
          permission_spec: "anyone:reader", type: "anyone", subject: nil, role: "reader"
        }
      ]
      """

  Example: A folder is given
    Given the command line "--folder=0ALLuhm2AwwlJUk9PVA"
    When the command line is parsed
    Then the parser should have succeeded
    And the folder_id attribute should be "0ALLuhm2AwwlJUk9PVA"

  # Failure cases

  Example: A sheet given without a name
    Given the command line "--sheet"
    When the command line is parsed
    Then the parser should have failed with the error "ERROR: missing argument: --sheet"

  Example: A permission is given without a permission spec
    Given the command line "--permission"
    When the command line is parsed
    Then the parser should have failed with the error "ERROR: missing argument: --permission"

  Example: A invalid permission is given
    Given the command line "--permission=anyone-writer"
    When the command line is parsed
    Then the parser should have failed with the error "ERROR: Invalid permission: anyone-writer"

  Example: The permission spec has an invalid type
    Given the command line "--permission=invalid:test@example.com:reader"
    When the command line is parsed
    Then the parser should have failed with the error "ERROR: Invalid permission type: invalid"

  Example: A permission spec has an invalid role
    Given the command line "--permission=user:test@example.com:invalid"
    When the command line is parsed
    Then the parser should have failed with the error "ERROR: Invalid permission role: invalid"

  Example: A subject is given for an anyone permission
    Given the command line "--permission=anyone:test@example.com:reader"
    When the command line is parsed
    Then the parser should have failed with the error "ERROR: An anyone permission must not have a subject"

  Example: A subject is not given for a user permission
    Given the command line "--permission=user:writer"
    When the command line is parsed
    Then the parser should have failed with the error "ERROR: A user permission must have a subject"

  Example: Data is given without a path
    Given the command line "--sheet=Summary --data"
    When the command line is parsed
    Then the parser should have failed with the error "ERROR: missing argument: --data"

  Example: Data is given with an non-existant path
    Given the command line "--sheet=Summary --data=nonexistent.csv"
    And the file "nonexistent.csv" does not exist
    When the command line is parsed
    Then the parser should have failed with the error "ERROR: Data file not found: nonexistent.csv"

  Example: The folder option is given twice
    Given the command line "--folder=0ALLuhm2AwwlJUk9PVA --folder=0ALLuhm2AwwlJUk9PVA"
    When the command line is parsed

  Example: A same sheet name is given twice
    Given the command line "--sheet=Summary --sheet=Summary"
    When the command line is parsed
    Then the parser should have failed with the error "ERROR: The sheet Summary was given more than once"

  Example: Data is given twice for the same sheet
    Given the command line "--sheet=Summary --data=data1.csv --data=data2.csv"
    And a file "data1.csv" containing:
      """
      1
      """
    And a file "data2.csv" containing:
      """
      2
      """
    When the command line is parsed
    Then the parser should have failed with the error "ERROR: Only one data file is allowed per sheet"
