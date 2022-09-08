<?PHP
echo "CREATE OR REPLACE DATABASE demo;" . "\n";
echo "USE demo;" . "\n";
echo "CREATE OR REPLACE TABLE users (id INT PRIMARY KEY AUTO_INCREMENT, user VARCHAR(255), pass VARCHAR(255));" . "\n";

$alpha = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
foreach (mb_str_split($alpha) as $charOne) {
    foreach (mb_str_split($alpha) as $charTwo) {
        $user = "testUsername".$charOne.$charTwo;
        $pass = password_hash("testPassword".$charOne.$charTwo, PASSWORD_DEFAULT, ["cost"=>4]);
        echo "INSERT INTO users (user, pass) VALUES ('".$user."', '".$pass."');" . "\n";
    }
}

echo "SHUTDOWN;" . "\n";
