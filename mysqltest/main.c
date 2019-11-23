#include <sys/time.h>
#include <stdio.h>
#include <mysql/mysql.h>

#define true 1

int main(char **args)
{
    MYSQL_RES *result;
    MYSQL_ROW row;
    MYSQL *connection, mysql;

    int state, err = 0;

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

    MYSQL_STMT *stmt = mysql_stmt_init(&mysql);
    if (!stmt)
    {
        fprintf(stderr, "%s\n", mysql_error(&mysql));
        return 1;
    }

    const char *query = "select `f_longtext_null` from mytable where pri = ?";
    err = mysql_stmt_prepare(stmt, query, 51);
    if (err)
    {
        fprintf(stderr, "failed to prepare query, %s\n", mysql_stmt_error(stmt));
        return 1;
    }

    MYSQL_BIND *param_binds = NULL;

    uint64_t *values = NULL;
    unsigned long paramCount = mysql_stmt_param_count(stmt);
    param_binds = (MYSQL_BIND *)calloc(sizeof(*param_binds), paramCount);
    values = (uint64_t *)calloc(sizeof(*values), paramCount);

    int val = 2;

    param_binds[0].buffer_type = MYSQL_TYPE_LONG;
    param_binds[0].buffer_length = 8;
    param_binds[0].buffer = (char *)&val;

    mysql_stmt_bind_param(stmt, param_binds);

    err = mysql_stmt_execute(stmt);
    if (err)
    {
        fprintf(stderr, "failed to execute query, %s\n", mysql_stmt_error(stmt));
        return 1;
    }

    MYSQL_RES *meta = mysql_stmt_result_metadata(stmt);
    if (!meta)
    {
        fprintf(stderr, "failed getting metadata, %s\n", mysql_stmt_error(stmt));
        return 1;
    }

    unsigned long col_count = mysql_num_fields(meta);
    MYSQL_BIND *result_binds = (MYSQL_BIND *)calloc(sizeof(MYSQL_BIND), col_count);
    MYSQL_FIELD *fields = mysql_fetch_fields(meta);

    char str_data[50];
    unsigned long col_no;
    for (col_no = 0; col_no < col_count; ++col_no)
    {
        result_binds[col_no].buffer_type = MYSQL_TYPE_STRING;
        // result_binds[col_no].buffer = (char *)malloc(fields[col_no].length);
        result_binds[col_no].buffer = (char *)str_data;
        result_binds[col_no].buffer_length = fields[col_no].length;
        result_binds[col_no].length = (unsigned long *)malloc(sizeof(unsigned long));
        result_binds[col_no].is_null = (my_bool *)malloc(sizeof(my_bool));
    }
    mysql_stmt_bind_result(stmt, result_binds);

    if (mysql_stmt_store_result(stmt))
    {
        fprintf(stderr, "failed to store results %s\n", mysql_stmt_error(stmt));
        return 1;
    }

    int row_count = 0;
    fprintf(stdout, "Fetching results ...\n");
    while (!mysql_stmt_fetch(stmt))
    {
        row_count++;
        fprintf(stdout, "  row %d\n", row_count);

        fprintf(stdout, "  COL: %s\n", str_data);
        // fprintf(stdout, "  COL: %s\n", result_binds[row_count].buffer);
    }

    // state = mysql_query(connection, "select `f_longtext_null` from mytable where pri = 2");
    // if (state != 0)
    // {
    //     fprintf(stderr, "%s\n", mysql_error(connection));
    //     return 1;
    // }

    // result = mysql_store_result(connection);

    // do
    // {
    //     row = mysql_fetch_row(result);
    //     if (!row)
    //     {
    //         break;
    //     }

    //     printf("id: %s, val: %s\n",
    //            (row[0] ? row[0] : "NULL"),
    //            (row[1] ? row[1] : "NULL"));

    // } while (true);
    // mysql_free_result(result);

    mysql_stmt_free_result(stmt);
    mysql_stmt_close(stmt);
    mysql_close(connection);

    printf("Done.\n");
}
