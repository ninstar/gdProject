@tool
extends HTTPRequest


signal etags_update_progress(index: int, total: int)
signal etags_update_finished(available_addon_list: PackedStringArray)
signal content_update_progress(index: int, total: int)
signal content_update_finished()


const ADDON_ZIP_PATH = "user://addon.zip"
const ETAG_FILENAME = "cache.txt"


var request_method := HTTPClient.METHOD_HEAD
var request_index: int = -1
var remote_etags: Dictionary = {}
var addons: Dictionary = {}
var requesting: bool = false


func _ready() -> void:
	request_completed.connect(_on_request_completed)
	download_file = ADDON_ZIP_PATH


func update_etags(addons_dict: Dictionary) -> void:
	addons = addons_dict
	request_index = 0
	request_method = HTTPClient.METHOD_HEAD
	_request_next()


func update_content() -> void:
	request_index = 0
	request_method = HTTPClient.METHOD_GET
	_request_next()


func remove_dir_recursive_absolute(path: String) -> void:
	if not path.begins_with("res://"):
		return
	
	# Remove files in the current directory
	for file_path: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file_path))
	
	# Remove files inside sub-directories recursively
	for dir_path: String in DirAccess.get_directories_at(path):
		remove_dir_recursive_absolute(path.path_join(dir_path))
	
	# Remove current directory
	DirAccess.remove_absolute(path)


func extract_addon_zip(addon_id: String) -> void:
	if not FileAccess.file_exists(ADDON_ZIP_PATH):
		return
	
	var addon: Dictionary = addons[addon_id]
	
	# Wipe current add-on
	for key: StringName in ["example_path", "addon_path"]:
		if DirAccess.dir_exists_absolute(addon[key]):
			remove_dir_recursive_absolute(addon[key])
		DirAccess.make_dir_recursive_absolute(addon[key])
	
	# Open .zip file and read its contents
	var zip_reader := ZIPReader.new()
	if zip_reader.open(ADDON_ZIP_PATH) == OK:
		
		# Extract each file
		for file_path: String in zip_reader.get_files():
			var res_path: String = "res://" + file_path.split("/", true, 1)[1]
			
			if not res_path.contains(addon["example_path"]) and not res_path.contains(addon["addon_path"]):
				continue
			
			if file_path.ends_with("/"):
				DirAccess.make_dir_recursive_absolute(res_path)
			else:
				var file := FileAccess.open(res_path, FileAccess.WRITE)
				file.store_buffer(zip_reader.read_file(file_path))
				file.close()
			
		zip_reader.close()


func _request_next() -> void:
	# Report progress
	if request_method == HTTPClient.METHOD_HEAD:
		etags_update_progress.emit(request_index, addons.size())
	else:
		content_update_progress.emit(request_index, addons.size())
	
	# Request data
	if request_index < addons.size():
		var addon_id: String = addons.keys()[request_index]
		request(addons[addon_id]["zip_url"], [], request_method)
		
		requesting = true
	else:
		if request_method == HTTPClient.METHOD_HEAD:
			var addons_to_update: Dictionary = {}
			var available_addon_list: PackedStringArray = []
			
			for addon_id: String in remote_etags.keys():
				# Load local etag file for current add-on
				var local_etag_file: String = addons[addon_id]["addon_path"].path_join(ETAG_FILENAME)
				var local_etag: String = ""
				
				if FileAccess.file_exists(local_etag_file):
					local_etag = JSON.parse_string(FileAccess.get_file_as_string(local_etag_file))
				
				# Compare remote etag to local etag
				if remote_etags[addon_id] != local_etag:
					available_addon_list.append(addon_id)
					addons_to_update[addon_id] = addons[addon_id].duplicate()
			
			# Emit list (only IDs)
			etags_update_finished.emit(available_addon_list)
			
			# Filter out updated add-ons
			addons = addons_to_update
		
		elif request_method == HTTPClient.METHOD_GET:
			# Delete download file
			if FileAccess.file_exists(ADDON_ZIP_PATH):
				DirAccess.remove_absolute(ADDON_ZIP_PATH)
			
			content_update_finished.emit()
		
		requesting = false


func cancel_progress() -> void:
	if not requesting:
		return
	
	cancel_request()
	requesting = false
	
	# Delete download file
	if FileAccess.file_exists(ADDON_ZIP_PATH):
		DirAccess.remove_absolute(ADDON_ZIP_PATH)


func _on_request_completed(result: int, _response_code: int, headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS:
		var addon_id: String = addons.keys()[request_index]
		
		if request_method == HTTPClient.METHOD_HEAD:
			var get_etag: Callable = func(headers: PackedStringArray) -> String:
				for tag: String in headers:
					if tag.begins_with("ETag: "):
						return tag.split(":")[1].strip_edges()
				return ""
			
			remote_etags[addon_id] = get_etag.call(headers)
			request_index += 1
		
		elif request_method == HTTPClient.METHOD_GET:
			extract_addon_zip(addon_id)
			
			# Save add-on remote etag locally
			var file := FileAccess.open(addons[addon_id]["addon_path"].path_join(ETAG_FILENAME), FileAccess.WRITE)
			file.store_line(JSON.stringify(remote_etags[addon_id], "\t"))
			file.close()
			
			request_index += 1
	
	_request_next()
