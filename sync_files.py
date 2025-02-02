import json
import shutil
import logging
from logging.handlers import RotatingFileHandler
from pathlib import Path
from datetime import datetime

def setup_logging():

    log_dir = Path(__file__).parent / 'logs'
    log_dir.mkdir(exist_ok=True)

    log_file = log_dir / f'sync_files_{datetime.now().strftime("%Y%m%d")}.log'
    
    logging.basicConfig(

        handlers=[

            RotatingFileHandler(
                log_file,
                maxBytes=1_048_576,  # 1MB
                backupCount=5,
                encoding='utf-8'
            ),

            logging.StreamHandler()

        ],

        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'

    )

def process_entry(base_dir, dest_name, source_info):

    # If the source is a dictionary, create a directory and process nested entries
    # Essentially we're assuming that this is another category.
    if isinstance(source_info, dict):

        current_dir = base_dir / dest_name
        current_dir.mkdir(exist_ok=True)

        for sub_dest, sub_source_info in source_info.items():

            logging.info(f"Processing {sub_dest} in {current_dir}")
            process_entry(current_dir, sub_dest, sub_source_info)

    else: # Otherwise, it's probably a file / folder

        source = Path(source_info)
        destination = base_dir / dest_name
        
        if not source.exists():
            logging.warning(f"Source {source} not found")
            return
        
        try:

            if source.is_file(): # If it's a file, copy the file to the appropriate destination

                shutil.copy2(source, destination)
                logging.info(f"Copied file {source} to {destination}")

            elif source.is_dir(): # If it's a directory, copy the entire directory over.

                if destination.exists() and destination.is_file():
                    logging.error(f"Cannot copy directory {source} to {destination} which is a file.")
                    return
                
                # Copy or merge if it already exists

                shutil.copytree(source, destination, dirs_exist_ok=True)
                logging.info(f"Copied directory {source} to {destination}")

            else:

                logging.warning(f"Source {source} is neither a file nor a directory")

        except Exception as e:

            logging.error(f"Error processing {source}: {str(e)}")
            raise

def sync_files():

    setup_logging()
    logging.info("Starting file sync")
    
    try:

        filemap_path = Path(__file__).parent / 'filemap.json'

        with open(filemap_path, 'r') as f:
            filemap = json.load(f)
        
        base_dir = Path(__file__).parent

        for category, mappings in filemap.items(): # For each key-value pair in filemap.json

            category_dir = base_dir / category

            category_dir.mkdir(exist_ok=True) # Ensure the category directory exists
            
            for dest_name, source_info in mappings.items(): # For each key-value pair in a category

                logging.info(f"Processing {dest_name} in {category}")

                # Process the value (can be a file, directory or another folder structure)
                process_entry(category_dir, dest_name, source_info)
        
        logging.info("File sync completed successfully")
        
    except Exception as e:
        logging.error(f"Error during sync: {str(e)}")
        raise

if __name__ == "__main__":
    sync_files()