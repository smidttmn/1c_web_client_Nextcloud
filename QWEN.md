## Qwen Added Memories
- Проект one_c_web_client_v3 на паузе (13.03.2026). Сервер drive.nppsgt.com (Nextcloud 30.0.17.2). Проблема: PHP OPcache кэширует старый код Application.php с registerAdminSettings() (метод не существует в NC 30). Решение: full_reinstall.sh с перезапуском PHP-FPM. Файлы готовы: /tmp/full_reinstall.sh, one_c_web_client_v3_fixed.tar.gz. Задача: nc1c-xa2 (status:pending). Репозиторий: https://github.com/smidttmn/one_c_web_client.git
- one_c_web_client_v3 - РАБОЧАЯ КОНФИГУРАЦИЯ Apache для прокси 1С:

1. ProxyPass: ProxyPass /one_c_web_client_v3 https://10.72.1.5/ retry=0 timeout=60
2. ProxyPassMatch: ProxyPassMatch ^/one_c_web_client_v3/(.*)$ https://10.72.1.5/$1
3. Прокси для путей 1С: ProxyPass /sgtbuh https://10.72.1.5/sgtbuh (и другие базы)
4. mod_substitute для переписывания URL:
   - AddOutputFilterByType SUBSTITUTE text/html
   - Substitute "s|href=\"/|href=\"/one_c_web_client_v3/|in"
   - Substitute "s|src=\"/|src=\"/one_c_web_client_v3/|in"
5. ProxyPassReverseCookieDomain 10.72.1.5 cloud.smidt.keenetic.pro
6. AllowOverride None (чтобы .htaccess не блокировал прокси)
7. SSLProxyEngine on, SSLProxyVerify none

JavaScript добавляет слэш на конце URL: path.endsWith('/') ? path : path + '/'

Тестировано на: cloud.smidt.keenetic.pro (Nextcloud 33, PHP 8.4, Apache 2.4.66)
1С сервер: https://10.72.1.5/sgtbuh/, https://10.72.1.5/zupnew/
- one_c_web_client_v3 - РАБОЧАЯ КОНФИГУРАЦИЯ Apache (ИТОГОВАЯ):

1. ProxyPass: ProxyPass /one_c_web_client_v3 https://10.72.1.5/ retry=0 timeout=60
2. ProxyPassMatch: ProxyPassMatch ^/one_c_web_client_v3/(.*)$ https://10.72.1.5/$1
3. Прокси для путей 1С: ProxyPass /sgtbuh https://10.72.1.5/sgtbuh (и другие базы)
4. mod_substitute для переписывания URL:
   - AddOutputFilterByType SUBSTITUTE text/html
   - Substitute "s|href=\"/|href=\"/one_c_web_client_v3/|in"
   - Substitute "s|src=\"/|src=\"/one_c_web_client_v3/|in"
5. ProxyPassReverseCookieDomain 10.72.1.5 cloud.smidt.keenetic.pro
6. AllowOverride None (чтобы .htaccess не блокировал прокси)
7. SSLProxyEngine on, SSLProxyVerify none

JavaScript добавляет слэш на конце URL: path.endsWith('/') ? path : path + '/'

Тестировано на: cloud.smidt.keenetic.pro (Nextcloud 33, PHP 8.4, Apache 2.4.66)
1С сервер: https://10.72.1.5/sgtbuh/, https://10.72.1.5/zupnew/

ВАЖНО: ProxyPass должен быть ДО всех исключений (ProxyPass /core !, /apps !, и т.д.)
