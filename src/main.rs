use std::io::Write;
use std::io::Read;
use std::fs::File;
use std::path::Path;

mod config;
mod bbio;

fn main() {
	let yaml_config = clap::load_yaml!("cli.yml");
	let matches = clap::App::from_yaml(yaml_config).get_matches();
	println!("Matches: {:?}", matches.subcommand_name());

	match matches.subcommand_name() {
		Some("config") => {
			let subcommand_matches = matches.subcommand_matches("config");
			if subcommand_matches.is_none() {
				println!("{}", cli_config(false))
			} else {
				if subcommand_matches.unwrap().is_present("clear"){ //Should always be true as it's the only argument
					println!("{}", cli_config(true));
				}
			}
		}
		Some("set_work_dir") => {
			//Safe to use unwraps because directory is a required argument
			let subcommand_matches = matches.subcommand_matches("set_work_dir").unwrap(); 
			let dir = subcommand_matches.value_of("directory").unwrap(); 
			println!("{}", cli_set_work_dir(dir));
		}
		Some("set_export_dir") => {
			//Safe to use unwraps because directory is a required argument
			let subcommand_matches = matches.subcommand_matches("set_export_dir").unwrap(); 
			let dir = subcommand_matches.value_of("directory").unwrap(); 
			println!("{}", cli_set_export_dir(dir));
		}
		Some("set_mod_dir") => {
			//Safe to use unwraps because directory is a required argument
			let subcommand_matches = matches.subcommand_matches("set_mod_dir").unwrap(); 
			let dir = subcommand_matches.value_of("directory").unwrap(); 
			println!("{}", cli_set_mod_dir(dir));
		}
		Some("set_game_dir") => {
			//Safe to use unwraps because directory is a required argument
			let subcommand_matches = matches.subcommand_matches("set_game_dir").unwrap(); 
			let dir = subcommand_matches.value_of("directory").unwrap(); 
			println!("{}", cli_set_game_dir(dir));
		}
		Some("update") => {
			let subcommand_matches = matches.subcommand_matches("set_mod_dir");
		}
		Some("export") => {

		}

		Some("log") => {println!("{}", cli_log());}
		Some(_) | None => {println!("Unknown command, use -h for help");}
	}
	
}


fn cli_config(clear: bool) -> String {
	if !clear {
		let config = match config::get_config() {
			Ok(config) => config,
			Err(error) => return format!("Error importing config: {:?}", error),
		};
		return config.to_string();
	} else {
		match config::set_config(config::Config::new(), true){
			Ok(()) => return "Cleared config".to_string(),
			Err(error) => return format!("Error clearing config: {:?}", error),
		}
	}
	
}

fn cli_set_work_dir(work_dir_str: &str) -> String {
	let work_dir_path = Path::new(&work_dir_str);
	if !work_dir_path.exists() { return "Directory does not exist, failed to set directory".to_string() }
	let mut new_config = config::Config::new();
	new_config.work_dir = Some(work_dir_str.to_string());
	match config::set_config(new_config, false) {
		Ok(()) => (),
		Err(error) => return format!("Error setting config: {:?}", error),
	};
	return format!("Set working directory to: {}", &work_dir_str);
}

fn cli_set_export_dir(export_dir_str: &str) -> String {
	let export_dir_path = Path::new(&export_dir_str);
	if !export_dir_path.exists() { return "Directory does not exist, failed to set directory".to_string() }
	let mut new_config = config::Config::new();
	new_config.export_dir = Some(export_dir_str.to_string());
	match config::set_config(new_config, false) {
		Ok(()) => (),
		Err(error) => return format!("Error setting config: {:?}", error),
	};
	return format!("Set Export directory to: {}", &export_dir_str);
}

fn cli_set_mod_dir(mod_dir_str: &str) -> String {
	let mod_dir_path = Path::new(&mod_dir_str);
	if !mod_dir_path.exists() { return "Directory does not exist, failed to set directory".to_string() }
	let mut new_config = config::Config::new();
	new_config.mod_dir = Some(mod_dir_str.to_string());
	match config::set_config(new_config, false) {
		Ok(()) => (),
		Err(error) => return format!("Error setting config: {:?}", error),
	};
	return format!("Set Export directory to: {}", &mod_dir_str);
}

fn cli_set_game_dir(game_dir_str: &str) -> String {
	let game_dir_path = Path::new(&game_dir_str);
	if !game_dir_path.exists() { return "Directory does not exist, failed to set directory".to_string() }
	let mut new_config = config::Config::new();
	new_config.game_dir = Some(game_dir_str.to_string());
	match config::set_config(new_config, false) {
		Ok(()) => (),
		Err(error) => return format!("Error setting config: {:?}", error),
	};
	return format!("Set Export directory to: {}", &game_dir_str);
}



fn cli_update(mod_dir_option: Option<&str>, compile: bool, delete_nuts: bool) -> String {
	let config = match config::get_config() {
		Ok(config) => (config),
		Err(error) => return format!("Error getting config: {:?}", error),
	};

	let game_dir_path = match config.game_dir {
		Some(string) => string,
		None => return "No game directory specified in config, use subcommand set_game_dir to set mod directory".to_string(),
	};

	return cli_export(mod_dir_option, Some(game_dir_path.as_ref()), compile, delete_nuts);
} 

fn cli_export(mod_dir_option: Option<&str>, export_dir_option: Option<&str>, compile: bool, delete_nuts: bool) -> String {
	let config = match config::get_config() {
		Ok(config) => (config),
		Err(error) => return format!("Error getting config: {:?}", error),
	};

	let mod_dir_path = match mod_dir_option {
		Some(string) => Path::new(string),
		None => {
			match config.mod_dir.as_ref() {
				Some(mod_string) => Path::new(mod_string),
				None => return format!("No mod directory in config, use subcommand set_mod_dir to set mod directory or add -m argument when using export or update"),
			}
		}
	};

	let export_dir_path = match export_dir_option {
		Some(string) => Path::new(string),
		None => {
			match config.export_dir.as_ref() {
				Some(export_string) => Path::new(export_string),
				None => return format!("No export directory in config, use subcommand set_export_dir to set game directory or add -ed argument when using export"),
			}
		}
	};

	match bbio::export_mod(mod_dir_path, export_dir_path, compile, delete_nuts) {
		Ok(()) => return "Mod exported successfully".to_string(),
		Err(error) => return format!("Error exporting mod: {:?}", error),
	}
}

fn cli_log() -> String {
	match bbio::open_log() {
		Ok(()) => return "Log opened".to_string(),
		Err(error) => return format!("Error opening log: {:?}", error)
	};
}