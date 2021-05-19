use crate::File;
use crate::Path;
use crate::Read;
use crate::Write;
use crate::Result;
#[derive(serde::Deserialize, serde::Serialize, Clone, Debug)]
pub struct Config {
	pub work_dir: Option<String>,
	pub mod_dir: Option<String>,
	pub export_dir: Option<String>,
	pub game_dir: Option<String>,
}
impl Config {
	pub fn new() -> Config {
		Config {
			work_dir: None,
			mod_dir: None,
			export_dir: None,
			game_dir: None,
		}
	}
	pub fn merge(&self, new_config: &Config) -> Config {
		let mut result = self.clone();
		if new_config.work_dir != None {
			result.work_dir = new_config.work_dir.clone();
		}
		if new_config.mod_dir != None {
			result.mod_dir = new_config.mod_dir.clone();
		}
		if new_config.export_dir != None {
			result.export_dir = new_config.export_dir.clone();
		}
		if new_config.game_dir != None {
			result.game_dir = new_config.game_dir.clone();
		}
		return result;
	}
}
impl std::fmt::Display for Config {
	fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
		write!(f, "Working Directory: {:?}\nCurrent Mod Directory: {:?}\nExport Directory: {:?}\nGame Directory: {:?}", self.work_dir, self.mod_dir, self.export_dir, self.game_dir)
	}
}

pub fn get_config() -> Result<Config> {
	let config_path = Path::new("config.yml");
	let mut config = Config::new();
	if config_path.exists() {
		let mut config_file = File::open(config_path)?;
		let mut config_contents = String::new();
		config_file.read_to_string(&mut config_contents)?;
		config = serde_yaml::from_str(&config_contents)?;
	}
	return Ok(config);
}

pub fn set_config(new_config: Config, force: bool) -> Result<()> {
	let config_path = Path::new("config.yml");
	let mut config_file = File::create(config_path)?;
	let config = match force {
		true => new_config.clone(),
		false => get_config()?.merge(&new_config),
	};
	let config_contents = serde_yaml::to_string(&config)?;
	config_file.write(config_contents.as_bytes())?;

	return Ok(());
}
