 
chmod +x install.sh

./install.sh

## Packages

```
sudo pacman -Syu
sudo pacman -S timeshift firefox git github-cli nodejs npm yay mariadb-libs mariadb mysql-workbench base-devel python python-pip

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
yay -S visual-studio-code-bin


sudo mariadb-upgrade --force
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql --service=mariadb
sudo systemctl enable mariadb.service
sudo systemctl start mariadb.service
sudo mysql_secure_installation
sudo mysqld_safe --skip-grant-tables --skip-networking &
mysql -u root

FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';

mysql -u root -p


SHOW DATABASES;
CREATE DATABASE mydb;
USE mydb;
SHOW TABLES;

gh auth status
gh auth login
gh repo clone adityathute/myProject
git status
git add .
git config --global user.name "Aditya Thute"
git config --global user.email "aadityathute@gmail.com"
git commit -m "Initial commit."
git push
git branch -a

python -m venv env
source env/bin/activate
pip install -r build/requirements.txt
pip freeze > build/requirements.txt
python manage.py runserver
npx webpack --config static/webpack/webpack.config.js
python manage.py makemigrations account
python manage.py migrate account
python manage.py makemigrations
python manage.py migrate
python manage.py createsuperuser

cd build/
npm install
