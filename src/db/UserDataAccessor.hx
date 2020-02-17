package db;

import haxe.crypto.BCrypt;
import haxe.ds.Either;
import TypeDefinitions;
import haxe.Json;

enum UserExistsResult {
	Yes;
	Missing;
	WrongPassword;
	Error(err:js.lib.Error);
}

enum FromTokenResult {
	User(username:String);
	Missing;
	Error(err:js.lib.Error);
}

enum QueryResult<T> {
	OK(data:T);
	Error(err:js.lib.Error);
}

class UserDataAccessor {
	static private var PEPPER:String = "$2y$10$CQpSdukJFXSyYKuCtg44.u0dXkA8mheHnil2yI4Q0FWtUS47GTVTO";
	/**
	 * Check if a user exists in database
	 * @param connection MySQLConnection The connection to the database
	 * @param uname String the username or login
	 * @param pwd 	String user password
	 * @param callback UserExistsResult->Void A callback to handle the response.
	 */
	public static function userExists(connection:MySQLConnection, uname:String, pwd:String, callback:UserExistsResult->Void):Void {
		connection.query("SELECT username, password FROM user WHERE username = ?", [uname], (error:js.lib.Error, results, fields) -> {
			if (error != null) {
				callback(Error(error));
				return;
			}
			if (results.length <= 0) {
				callback(Missing);
				return;
			}
			try {
				callback(BCrypt.verify(pwd + PEPPER, results[0].password) ? Yes : WrongPassword);
			} catch (e:Dynamic) {
				trace(e);
				callback(WrongPassword);
			}
		});
	}

	/**
	 * Insert a user in database.
	 * @param connection MySQLConnection The connection to the database
	 * @param user User user to insert
	 * @param callback Either<js.lib.Error, Bool>->Void A callback to handle the response, response can be either the "user is in database" information or a JavaScript error.
	 */
	public static function createUser(connection:MySQLConnection, user:User, callback:Either<js.lib.Error, Bool>->Void) {
		var encodedPassword = BCrypt.encode(user.password + PEPPER, BCrypt.generateSalt());
		connection.query("INSERT INTO user(id, username, password, email)  VALUES(?,?,?,?)", [user.id, user.username, encodedPassword, user.email],
			(error:js.lib.Error, results, fields) -> {
				if (error != null) {
					callback(Left(error));
					return;
				}
				callback(Right(true));
			});
	}

	/**
	 * Insert a token in database
	 * @param connection 
	 * @param user 
	 * @param durationInMinutes 
	 * @return String
	 */

	public static function createToken(connection:MySQLConnection, username:String, durationInMinute:Float = 0, callback:Either<js.lib.Error, String>->Void) {
		var token:String = BCrypt.generateSalt(10,BCrypt.Revision2B);
		var durationInMs:Float = durationInMinute * 60 * 1000;
		connection.query("INSERT INTO token(id, id_user, expiration) VALUES(?,?,?)", [token, username, formatDateForMySQL(DateTools.delta(Date.now(), durationInMs))
		], (error:js.lib.Error, results, fields) -> {
			if (error != null) {
				callback(Left(error));
				return;
			}
			callback(Right(token));
		});
	}

	/**
	 * Get user login from token if the token is valid
	 * @param connection 
	 * @param token 
	 * @param callback 
	 */

	public static function fromToken(connection:MySQLConnection, token:String, callback:FromTokenResult->Void):Void {
		connection.query("DELETE FROM token WHERE expiration < now()", (error:js.lib.Error, results, fields) -> {
			connection.query("SELECT user.username, token.expiration FROM user INNER JOIN token ON user.username = token.id_user WHERE token.id = ?", [token], (error:js.lib.Error, results, fields) -> {
				if (error != null) {
					callback(Error(error));
					return;
				}
				if (results.length <= 0) {
					callback(Missing);
					return;
				}
				callback(User(results[0].username));
			});
		});
	}


	/**
	 * Save data to a specific user
	 * @param connection 
	 * @param username 
	 * @param data 
	 * @param callback 
	 */
	public static function save(connection:MySQLConnection, username:String, data:Dynamic, callback:QueryResult<Dynamic>->Void):Void {
		connection.query("UPDATE user SET data=? WHERE username=?", [Json.stringify(data), username],
		(error:js.lib.Error, results, fields) -> {
			if (error != null) {
				callback(Error(error));
				return;
			}
			callback(OK(results));
		});
	}

	/**
	 * Show data of a specific user 
	 * @param connection 
	 * @param username 
	 * @param callback 
	 */
	public static function load(connection:MySQLConnection, username:String, callback:QueryResult<Dynamic>->Void):Void {
		connection.query("SELECT data FROM user WHERE username=?", [username],
		(error:js.lib.Error, results, fields) -> {
			if (error != null) {
				callback(Error(error));
				return;
			}
			callback(OK(results[0].data));
		});
	}

	private static function formatDateForMySQL(date:Date):String {
		return DateTools.format(date, "%Y-%m-%d_%H:%M:%S");
	}
}
