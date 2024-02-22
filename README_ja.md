# ディレクトリマージ
本リポジトリのスクリプトは、複数のディレクトリをマージして、1つのディレクトリにする機能を持ちます。
本スクリプトは、ディレクトリを次のようにマージします。
- どちらか片方のディレクトリにのみ含まれるファイルは、そのまま残します。
- 同一のファイルがある場合は、そのうちの一つを残します。どれを残すかは、選択することができます。

実のところ、本スクリプトは自動的に上記を行ってくれるわけではありません。
むしろ、使用者が、目的に応じて複数のスクリプトを順番に実行する必要があります。
この仕様は不便ではありますが、利点もあります。
それは作業内容をステップごとに確認できることです。
これにより、ディレクトリのマージ時に誤ってデータを削除することを防ぐことができます。

## 使い方
### ディレクトリの走査
`list_files.rb`でディレクトリを走査し、ディレクトリに含まれるファイルの情報を一覧にしたファイルリストを作成します。
ファイルリストの形式は、CSV形式です。

例えば、次の例は、`./directory_a`、`./directory_b`を再帰的に走査し、その結果を`files.csv`に保存します。
また、ログを`list_files.log`に出力します。
```
ruby list_files.rb -r -o files.csv --log-file list_files.log ./directory_a ./directory_b
```

### ファイルリストのフィルタリング
`filter_file_list.rb`は、ファイルリストをフィルタリングし、操作対象（削除や移動をしたいファイル）を抽出します。

例えば、次の例は、重複したファイルのうち、ファイルリスト`files.csv`の最初にあるもの以外をフィルタリングし、その結果を`filtered_files`に保存します。
また、ログを`filter_file_list.log`に出力します。
```
ruby filter_file_list.rb -f 'count >= 2' -f 'index > 1' -o filtered_files.csv --log-file filter_file_list.log files.csv
```

### ファイルの削除
ファイルリストに存在するファイルを全て削除します。

例えば、次の例は、ファイルリスト`files.csv`にリストされる全てのファイルを削除し、その結果を`deleted_files.csv`に保存します。
```
ruby delete_files.rb -o deleted_files.csv --log-file delete_files.log files.csv
```

### ファイルの移動
ファイルリストに存在するファイルを指定のパスへ全て移動します。

-dオプションで、移動先パスを指定することができます。
移動先パスには、パラメータを埋め込むことができます。
例えば、`./{modified_time}/{file_name}`と指定した場合、modified_timeを表すディレクトリを作成後、そのディレクトリへファイルを移動します。

例えば、次の例は、ファイルリスト`files.csv`にリストされる全てのファイルを`./move`ディレクトリへ移動し、その結果を`moved_files.csv`に保存します。
```
ruby move_files.rb -o moved_files.csv --log-file move_files.log -d "./move/{file_name}" files.csv
```
