#include <sys/time.h>
#include <stdio.h>
#include <mysql/mysql.h>

int main(char **args)
{
    MYSQL_RES *result;
    MYSQL_ROW row;
    MYSQL *connection, mysql;
    int state;

    mysql_init(&mysql);
    connection = mysql_real_connect(&mysql,
                                    "dbstorage",
                                    "root",
                                    "qwerty",
                                    "tester",
                                    3360,
                                    0,
                                    CLIENT_MULTI_STATEMENTS | CLIENT_MULTI_RESULTS);

    if (connection == NULL)
    {
        fprintf(stderr, "%s\n", mysql_error(&mysql));
        return 1;
    }

    state = mysql_query(connection, "select `f_longtext` from mytable where pri = 2");
    if (state != 0)
    {
        fprintf(stderr, "%s\n", mysql_error(connection));
        return 1;
    }

    result = mysql_store_result(connection);
    while ((row = mysql_fetch_row(result)) != NULL)
    {
        printf("id: %s, val: %s\n",
               (row[0] ? row[0] : "NULL"),
               (row[1] ? row[1] : "NULL"));
    }

    mysql_free_result(result);
    mysql_close(connection);

    printf("Done.\n");
}
