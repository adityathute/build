 
chmod +x install.sh && ./install.sh

## Packages

```
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
