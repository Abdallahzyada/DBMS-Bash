#!/bin/bash

if [ ! -d ./database ]; then
    mkdir ./database
    cd ./database
else
    cd ./database
fi

# Function to show the main menu
show_main_menu() {
    while true; do
        echo "----- Main Menu -----"
        echo "1. Create Database"
        echo "2. List Databases"
        echo "3. Connect To Database"
        echo "4. Drop Database"
        echo "5. Exit"
        echo "Enter your choice:"
        read choice
        case $choice in
            1) 
            create_database;;
            2) 
            list_databases;;
            3) 
            connect_to_database;;
            4) 
            drop_database;;
            5) 
            exit;;
            *)
            echo "Invalid choice.";;
        esac
    done
}


# Function to show the database menu
show_database_menu() {
    while true; do
        echo "----- Database Menu -----"
        echo "1. Create Table"
        echo "2. List Tables"
        echo "3. Drop Table"
        echo "4. Insert into Table"
        echo "5. Select From Table"
        echo "6. Delete From Table"
        echo "7. Update Table"
        echo "8. Back to Main Menu"
        echo "Enter your choice:"
        read choice
        case $choice in
            1) 
            create_table;;
            2)
            list_tables;;
            3) 
            drop_table;;
            4) 
            insert_into_table;;
            5) 
            select_from_table;;
            6) 
            delete_from_table;;
            7) 
            update_table;;
            8) 
            cd ./..
            show_main_menu ;;
            *) echo "Invalid choice.";;
        esac
    done
}

# Function to validate the name
validate_name() {
  if [[ ! $1 =~ ^[a-zA-Z]+$ ]]; then
    echo "Invalid name: $1. Name must consist of letters only."
    $2
  fi
}

# Function to create a new database
create_database() {
  echo "Enter the name of the new database:"
  read database_name
  
  validate_name "$database_name" show_main_menu

  if [ -d "$database_name" ]; then
    echo "The database already exists. Please choose a different name."
  else
    mkdir "$database_name"
    echo "Database created successfully."
  fi
}

# Function to list all databases
list_databases() {
    echo "List of databases:"
    ls -d */
}

# Function to connect to a specific database
connect_to_database() {
    echo "Enter the name of the database to connect to:"
    read database_name
    if [ -d "$database_name" ]; then
        cd "$database_name"
        echo "Connected to the database: $database_name"
        show_database_menu
    else
        echo "Database does not exist."
    fi
}

# Function to drop a database
drop_database() {
    echo "Enter the name of the database to drop:"
    read database_name
    if [ -d "$database_name" ]; then
        rm -r "$database_name"
        echo "Database dropped successfully."
    else
        echo "Database does not exist."
    fi
}

# Function to list all tables in the current database
list_tables() {
    echo "List of tables:"
    ls
}

# Function to create a new table
create_table() {
  echo "Enter the name of the new table:"
  read table_name
  
  validate_name "$table_name" show_database_menu

  # Check if the table already exists
  if [ -f "$table_name" ]; then
    echo "Table '$table_name' already exists."
    return
  fi

  echo "Enter column names (comma-separated):"
  read column_names
  echo "Enter column types (comma-separated):"
  read column_types
  echo "Enter the primary key column:"
  read primary_key

  # Verify column names for special characters
  IFS=',' read -ra column_names_array <<< "$column_names"
  
  for column_name in "${column_names_array[@]}"; do
    if [[ ! "$column_name" =~ ^[[:alnum:],]+$ ]]; then
      echo "Invalid column name: $column_name"
      return
    fi
  done
  
  #Verify column datatypes
  IFS=',' read -ra types <<< "$column_types"
  valid_types=("int" "INT" "INTEGER" "interger" "float" "FLOAT" "char" "CHAR" "VARCHAR" "varchar" "text" "TEXT" "string" "STRING" "str" "STR")

  for type in "${types[@]}"; do
    if ! [[ " ${valid_types[@]} " =~ " $type " ]]; then
      echo "Invalid column type: $type"
      return
    fi
  done

  # Check if the primary key column exists in the column names
  if ! [[ " ${column_names_array[@]} " =~ " $primary_key " ]]; then
    echo "Primary key column '$primary_key' does not exist in the column names."
    return
  fi

  # Check if any column already exists in the table
  existing_columns=""
  if [ -f "$table_name" ]; then
    existing_columns=$(sed -n '1p' "$table_name")
  fi
  IFS=',' read -ra existing_columns_array <<<"$existing_columns"

  for column_name in "${existing_columns_array[@]}"; do
    if [[ " ${column_names_array[@]} " =~ " $column_name " ]]; then
      echo "Column '$column_name' already exists in the table."
      return
    fi
  done

  # Create a file with the table name and write column information to it
  echo "$column_names" > "$table_name"
  echo "$column_types" >> "$table_name"
  echo "$primary_key" >> "$table_name"

  echo "Table created successfully."
}



# Function to drop a table from the current database
drop_table() {
    echo "Enter the name of the table to drop:"
    read table_name
    if [ -f "$table_name" ]; then
        rm "$table_name"
        echo "Table dropped successfully."
    else
        echo "Table does not exist."
    fi
}



insert_into_table() {
  echo "Enter the name of the table to insert into:"
  read table_name
  if [ -f "$table_name" ]; then
  
    # Read column names from the table file
    column_names=$(sed -n '1p' "$table_name")
    IFS=',' read -ra column_array <<<"$column_names"

    # Read column types from the table file
    column_types=$(sed -n '2p' "$table_name")
    IFS=',' read -ra type_array <<<"$column_types"

    # Read primary key column from the table file
    primary_key=$(sed -n '3p' "$table_name")

    declare -a data_values

    # Prompt the user to enter data for each column
    for ((i=0; i<${#column_array[@]}; i++)); do
      column="${column_array[$i]}"
      echo "Enter value for $column:"
      read value

      # Validate the data type based on the column type
      expected_type="${type_array[$i]}"
      if ! validate_data_type "$value" "$expected_type"; then
        echo "Invalid data type for $column. Expected $expected_type."
        return
      fi

      data_values+=("$value")
    done

    # Check if the primary key value already exists in the table
    primary_key_index=$(get_array_index "$primary_key" "${column_array[@]}")
    primary_key_value=${data_values[$primary_key_index]}
    existing_row=$(sed -n '4,$p' "$table_name" | grep -E "^$primary_key_value")
    if [ -n "$existing_row" ]; then
      echo "Row with primary key '$primary_key_value' already exists in the table."
    else
      # Convert data values to a comma-separated string
      data_row=$(IFS=','; echo "${data_values[*]}")

      # Append the new data row to the table file
      echo "$data_row" >> "$table_name"

      echo "Data inserted successfully."
    fi
    
  else
    echo "Table does not exist."
  fi
}


# Function to select from a table
select_from_table() {
  echo "Enter the name of the table to select from:"
  read table_name

  if [ -f "$table_name" ]; then
  
    # Read column names from the table file
    column_names=$(sed -n '1p' "$table_name")
    IFS=',' read -ra column_array <<<"$column_names"

    # Prompt the user to choose the column selection option
    echo "Choose the column selection option:"
    echo "1. Select all columns"
    echo "2. Select specific columns"
    read column_selection_option

    # Validate the column selection option
    if [ "$column_selection_option" = "1" ]; then
      # Select all columns
      selected_columns=("${column_array[@]}")
    elif [ "$column_selection_option" = "2" ]; then
      # Prompt the user to enter the columns to retrieve
      echo "Enter the columns to retrieve (comma-separated):"
      read columns_to_retrieve

      # Split the entered columns into an array
      IFS=',' read -ra selected_columns <<<"$columns_to_retrieve"
      
      for column_name in "${selected_columns[@]}"; do
        if [[ ! "$column_name" =~ ^[[:alnum:],]+$ ]]; then
          echo "Invalid column name: $column_name"
          return
        fi
      done

      # Verify that the selected columns exist in the table
      for column in "${selected_columns[@]}"; do
        if [[ ! " ${column_array[@]} " =~ " $column " ]]; then
          echo "Column '$column' does not exist in the table."
          return
        fi
      done
    else
      echo "Invalid option selected."
      return
    fi

    # Prompt the user to choose the row selection option
    echo "Choose the row selection option:"
    echo "1. Select all rows"
    echo "2. Select a specific row by primary key"
    read row_selection_option

    if [ "$row_selection_option" = "1" ]; then
      # Read data rows from the table file
      data_rows=$(sed -n '4,$p' "$table_name")

    elif [ "$row_selection_option" = "2" ]; then
      # Prompt the user to enter the primary key value
      echo "Enter the primary key value:"
      read primary_key_value

      # Check if the primary key value exists in the table
      primary_key=$(sed -n '3p' "$table_name")
      primary_key_index=$(get_array_index "$primary_key" "${column_array[@]}")
      primary_key_column=${column_array[primary_key_index]}

      primary_key_exists=$(awk -F ',' -v pk_val="$primary_key_value" -v pk_index="$primary_key_index" '
        NR>1 && $((pk_index+1)) == pk_val { found=1; print $((pk_index+1)); exit }
        END { if (found != 1) print "not_found" }' "$table_name")

      if [ "$primary_key_exists" = "not_found" ]; then
        echo "Primary key value '$primary_key_value' does not exist in the table."
        return
      fi

      # Read the row with the specified primary key value
      data_rows=$(awk -F ',' -v pk_val="$primary_key_value" -v pk_index="$primary_key_index" '
        BEGIN { OFS=","; found=0 }
        NR>1 && $((pk_index+1)) == pk_val { found=1; print $0 }
        END { if (found != 1) print "not_found" }' "$table_name")
      
    else
      echo "Invalid option selected."
      return
    fi

    # Print the selected columns with their respective data
    for column in "${selected_columns[@]}"; do
      echo -n "$column,"
    done | sed 's/,$/\n/'

    # Retrieve the selected columns for each data row
    while IFS=',' read -r -a values; do
      for column_index in "${!selected_columns[@]}"; do
        selected_column="${selected_columns[column_index]}"
        for ((i = 0; i < ${#column_array[@]}; i++)); do
          if [ "${column_array[i]}" = "$selected_column" ]; then
            echo -n "${values[i]},"
            break
          fi
        done
      done | sed 's/,$/\n/'
    done <<< "$data_rows"
  else
    echo "Table does not exist."
  fi
}

# Function to delete from a table
delete_from_table() {
  echo "Enter the name of the table to delete from:"
  read table_name

  if [ -f "$table_name" ]; then
  
    # Read column names from the table file
    column_names=$(sed -n '1p' "$table_name")
    IFS=',' read -ra column_array <<<"$column_names"
    
    # Read and Validate the primary key column
    echo "Enter the primary key column name:"
    read primary_key_column
    
    if ! contains_element "$primary_key_column" "${column_array[@]}"; then
      echo "Invalid primary key column: $primary_key_column"
      return
    fi

    echo "Enter the value of the primary key to delete:"
    read primary_key_value

    # Read existing rows from the table file
    existing_rows=$(sed -n '2,$p' "$table_name")

    # Create a temporary file to store the updated table data
    temp_file=$(mktemp)

    # Write column names to the temporary file
    echo "$column_names" >> "$temp_file"

    # Flag to track if the primary key value exists and row deletion status
    primary_key_exists=false
    row_deleted=false

    # Iterate over existing rows and write only the non-matching rows to the temporary file
    while IFS= read -r row; do
      IFS=',' read -ra row_array <<<"$row"
      primary_key_index=$(get_array_index "$primary_key_column" "${column_array[@]}")

      # Check if the primary key value matches the specified condition
      if [[ "${row_array[$primary_key_index]}" == "$primary_key_value" ]]; then
        primary_key_exists=true
        row_deleted=true
      else
        echo "$row" >> "$temp_file"
      fi
    done <<<"$existing_rows"

    if ! $primary_key_exists; then
      echo "Primary key value does not exist."
      rm "$temp_file" 
      return
    fi

    if ! $row_deleted; then
      echo "No rows deleted."
      rm "$temp_file"
      return
    fi

    # Replace the original table file with the updated table data
    mv "$temp_file" "$table_name"

    echo "Data deleted successfully."
  else
    echo "Table does not exist."
  fi
}

validate_data_type() {
  value="$1"
  expected_type="$2"

  # Perform data type validation based on the expected type
  case "$expected_type" in
    "int"|"INT"|"INTEGER"|'integer')
      if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        return 1
      fi
      ;;
    "float"|"FLOAT")
      if ! [[ "$value" =~ ^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]]; then
        return 1
      fi
      ;;
    "char"|"CHAR"|"VARCHAR"|"varchar"|"text"|"TEXT"|"string"|"STRING"|"str"|"STR")
       if ! [[ "$value" =~ ^[[:alpha:]]+$ ]]; then
       return 1
       fi
      ;;
    *)
      echo "Unknown data type: $expected_type"
      return 1
      ;;
  esac

  return 0
}

get_array_index() {
  local search_value=$1
  shift
  local array=("$@")
  local index=-1
  for i in "${!array[@]}"; do
    if [[ "${array[$i]}" = "$search_value" ]]; then
      index=$i
      break
    fi
  done
  echo "$index"
}

contains_element() {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}


update_table() {
  echo "Enter the name of the table to update:"
  read table_name
  if [ -f "$table_name" ]; then
  
    
  
    # Read column names from the table file
    column_names=$(sed -n '1p' "$table_name")
    IFS=',' read -ra column_array <<<"$column_names"
    
    

    # Read column types from the table file
    column_types=$(sed -n '2p' "$table_name")
    IFS=',' read -ra type_array <<<"$column_types"

    # Prompt the user to enter the current primary key value
    echo "Enter the current primary key value:"
    read current_primary_key_value

    # Check if the current primary key value exists in the table
      primary_key=$(sed -n '3p' "$table_name")
      primary_key_index=$(get_array_index "$primary_key" "${column_array[@]}")

      existing_row=$(awk -F ',' -v pk_val="$primary_key_value" -v pk_index="$primary_key_index" '
        NR>1 && $((pk_index+1)) == pk_val { found=1; print $((pk_index+1)); exit }
        END { if (found != 1) print "not_found" }' "$table_name")

      if [ "$existing_row" = "not_found" ]; then
        echo "Primary key value '$primary_key_value' does not exist in the table."
        return
      fi

    declare -a data_values

    # Prompt the user to enter new values for each column
    for ((i=0; i<${#column_array[@]}; i++)); do
      column="${column_array[$i]}"
      data_type="${type_array[$i]}"
      echo "Enter new value for $column (${data_type}):"
      read value
      
      # Validate the data type
      if ! validate_data_type "$value" "$data_type"; then
        echo "Invalid data type for $column. Data not updated."
        return
      fi

      data_values+=("$value")
    done

    # Construct the updated data row
    updated_row=$(IFS=','; echo "${data_values[*]}")
    
    new_primary_key_value=${data_values[$primary_key_index]}
    if [ "$new_primary_key_value" != "$current_primary_key_value" ]; then
      echo "primary key value Must be the same. Data not updated."
      return
    fi

    # Update the table file
    sed -i "/$current_primary_key_value,/c$updated_row" "$table_name"

    echo "Table updated successfully."
    echo "Updated row: $updated_row"
  else
    echo "Table does not exist."
  fi
}



show_main_menu
