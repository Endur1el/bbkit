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
		Some("update") => {},
		Some("config") => {println!("{}", cli_config());}
		Some(_) | None => {println!("Unknown command, use -h for help");}
	}
	
}


fn cli_config() -> String{
	let config = match config::get_config() {
		Ok(config) => config,
		Err(error) => return format!("Error importing config: {:?}", error),
	};
	return config.to_string();
}