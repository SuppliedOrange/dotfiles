import json
import shutil
import logging
from pathlib import Path
from datetime import datetime

def setup_logging():
    log_dir = Path(__file__).parent / 'logs'
    log_dir.mkdir(exist_ok=True)
    
    logging.basicConfig(
        handlers=[
            logging.FileHandler(log_dir / f'sync_files_{datetime.now().strftime("%Y%m%d")}.log'),
            logging.StreamHandler()
        ],
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )

def sync_files():
    setup_logging()
    logging.info("Starting file sync")
    
    try:
        # Get absolute path to filemap.json
        filemap_path = Path(__file__).parent / 'filemap.json'
        with open(filemap_path, 'r') as f:
            filemap = json.load(f)
        
        base_dir = Path(__file__).parent

        # Process each category
        for category, mappings in filemap.items():
            
            # Create category directory if it doesn't exist
            category_dir = base_dir / category
            category_dir.mkdir(exist_ok=True)
            
            # Copy each file
            for dest_file, source_path in mappings.items():

                logging.info(f"Processing {dest_file} in {category}")

                source = Path(source_path)
                destination = category_dir / dest_file
                
                if source.exists():
                    shutil.copy2(source, destination)
                    logging.info(f"Copied {source} to {destination}")
                else:
                    logging.warning(f"Source file {source} not found")
        
        logging.info("File sync completed successfully")
    except Exception as e:
        logging.error(f"Error during sync: {str(e)}")
        raise

if __name__ == "__main__":
    sync_files()