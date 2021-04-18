use std::io::Write;



fn main() {

}

fn decompile_cnut (file_source_path: &std::path::Path, file_target_path: &std::path::Path) -> Result<(), std::io::Error> {
	let nutcracker_path = std::env::current_dir().unwrap().join("adams_kit").join("nutcracker.exe");
	let bbsq_path = std::env::current_dir().unwrap().join("adams_kit").join("bbsq.exe"); 
	//Above two lines should be declared somewhere globaly and only once

	let temp_file_path = file_source_path.parent().unwrap().join("temp.nut");
	match std::fs::copy(&file_source_path,&temp_file_path){	//Make temprorary file to prepare for bbsq
		Ok(_) => (),
		Err(error) =>{ 
			println!("Failed to copy file: {:?}, error: {:?}", file_source_path, error);
			return Err(error);
		}
	}

	let bbsq_out = std::process::Command::new(&bbsq_path)
									.args(&["-d", &temp_file_path.to_str().unwrap()])
									.output()
									.expect("Failed to find bbsq (has the file been moved?)");

	let nutcracker_out = std::process::Command::new("cmd")
										  .args(&["/C", &nutcracker_path.to_str().unwrap()])
										  .args(&[&temp_file_path.to_str().unwrap(), ">", file_target_path.to_str().unwrap()])
										  .output()
										  .expect("Failed to run nutcracker.exe (has the file been moved?)");

	println!("bbsq: {:?} nutcracker: {:?}", bbsq_out, nutcracker_out);

	match std::fs::remove_file(temp_file_path) {
				Ok(()) => (),
				Err(error) => {
					println!("Failed to delete temp.cnut: {}", error);
					return Err(error);
					}
				}

	return Ok(())
}

fn compile_nut(file_source_path: &std::path::Path) -> Result<(), std::io::Error> {
	let bbsq_path = std::env::current_dir().unwrap().join("adams_kit").join("bbsq.exe"); 

	let bbsq_out = std::process::Command::new(&bbsq_path)
									.args(&["-e", &file_source_path.to_str().unwrap()])
									.output()
									.expect("Failed to find bbsq (has the file been moved?)");

	println!("bbsq: {:?}", bbsq_out);

	return Ok(())
}

fn import_mod (mod_file_path: &std::path::Path, target_dir: &std::path::Path, delete_cnuts: bool) -> i32{
	//Return 0 = Ok
	//1 = Error before file changes
	//2 = Error after file changes
	//3 = Error with deleting clutter files

	let imported_mod_path = target_dir.join(mod_file_path.file_stem().unwrap());

	let mut archive = match zip::ZipArchive::new(std::fs::File::open(mod_file_path).unwrap()) {
		Ok(zip) => zip,
		Err(error) => {
			println!("Error: {}", error);
			return 1;
		}
	};

	match archive.extract(&imported_mod_path){
		Ok(()) => println!("Unzipped successfully"),
		Err(error) => {
			println!("Faild to Extract zip: {}", error);
			return 2;
		}
	}


	for file in walkdir::WalkDir::new(&imported_mod_path){ //Walk through all files in unzipped folder
		let file_path = file.unwrap().path().to_owned();

		if file_path.is_dir() {
			continue;
		}

		if file_path.extension().unwrap().eq("cnut") {

			let mut file_target_path = file_path.clone();
			file_target_path.set_extension("nut");

			match decompile_cnut(&file_path, &file_target_path){
					Ok(()) => (),
					Err(error) => {
						println!("Failed to decompile cnut: {}", error);
						return 3;
						}
				}


			if delete_cnuts {
				match std::fs::remove_file(file_path){
					Ok(()) => (),
					Err(error) => {
						println!("Failed to delete file: {}", error);
						return 3;
						}
				}
			}
		}
	}

	return 0
}

fn export_mod (mod_source_path: &std::path::Path, target_dir: &std::path::Path, compile: bool, delete_nuts: bool) -> Result<(), std::io::Error>{
	let mut mod_target_path = target_dir.join(mod_source_path.file_stem().unwrap());
	mod_target_path.set_extension("zip");
	println!("file: {:?}", mod_target_path);
	let mod_target_file = std::fs::File::create(mod_target_path).unwrap();
	let mut mod_target_zip = zip::ZipWriter::new(&mod_target_file);

	for walk_file in walkdir::WalkDir::new(&mod_source_path){
		let walk_file_path = walk_file.as_ref().unwrap().path();

		if walk_file_path.is_file() {

			if compile {
				match compile_nut(walk_file_path) {
					Ok(()) => (),
					Err(error) => return Err(error),
				}

				let mut walk_cnut_path = walk_file_path.to_owned();
				walk_cnut_path.set_extension("cnut");
				mod_target_zip.start_file(walk_cnut_path.strip_prefix(&mod_source_path).unwrap().to_str().unwrap(),
										  zip::write::FileOptions::default())?;
				mod_target_zip.write(&std::fs::read(walk_cnut_path).unwrap())?;

			}

			if !delete_nuts {
				mod_target_zip.start_file(walk_file_path.strip_prefix(&mod_source_path).unwrap().to_str().unwrap(),
										  zip::write::FileOptions::default())?;
				mod_target_zip.write(&std::fs::read(walk_file_path).unwrap())?;
			}
		}
	}
	mod_target_zip.finish()?;

	return Ok(());
}

fn open_log () ->  Result<(), std::io::Error> {
	let log = dirs_next::document_dir().unwrap();
	let log = log.join("Battle Brothers").join("log.html");
	match open::that(&log.into_os_string()){
		Ok(_) => (),
		Err(error) => return Err(error),
	}

	return Ok(())
}