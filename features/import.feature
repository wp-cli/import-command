Feature: Import content.

  Scenario: Importing requires plugin installation
    Given a WP install

    When I try `wp import file.xml --authors=create`
    Then STDERR should contain:
      """
      Error: WordPress Importer needs to be installed. Try 'wp plugin install wordpress-importer --activate'.
      """

  @require-wp-5.2 @require-mysql
  Scenario: Basic export then import
    Given a WP install
    And I run `wp site empty --yes`
    And I run `wp post generate --post_type=post --count=4`
    And I run `wp post generate --post_type=page --count=3`
    When I run `wp post list --post_type=any --format=count`
    Then STDOUT should be:
      """
      7
      """

    When I run `wp export`
    Then save STDOUT 'Writing to file %s' as {EXPORT_FILE}

    When I run `wp site empty --yes`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=any --format=count`
    Then STDOUT should be:
      """
      0
      """

    When I run `wp plugin install wordpress-importer --activate`
    Then STDERR should not contain:
      """
      Warning:
      """

    When I run `wp import {EXPORT_FILE} --authors=skip`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=any --format=count`
    Then STDOUT should be:
      """
      7
      """

    When I run `wp import {EXPORT_FILE} --authors=skip --skip=image_resize`
    Then STDOUT should not be empty

  @require-wp-5.2 @require-mysql
  Scenario: Export and import a directory of files
    Given a WP install
    And I run `mkdir export-posts`
    And I run `mkdir export-pages`
    And I run `wp site empty --yes`

    When I run `wp post generate --count=50`
    And I run `wp post generate --post_type=page --count=50`
    And I run `wp post list --post_type=post,page --format=count`
    Then STDOUT should be:
      """
      100
      """

    When I run `wp export --dir=export-posts --post_type=post`
    And I run `wp export --dir=export-pages --post_type=page`
    Then STDOUT should not be empty

    When I run `wp site empty --yes`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=post,page --format=count`
    Then STDOUT should be:
      """
      0
      """

    When I run `find export-* -type f | wc -l`
    Then STDOUT should contain:
      """
      2
      """

    When I run `wp plugin install wordpress-importer --activate`
    Then STDERR should not contain:
      """
      Warning:
      """

    When I run `wp import export-posts --authors=skip --skip=image_resize`
    And I run `wp import export-pages --authors=skip --skip=image_resize`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=post,page --format=count`
    Then STDOUT should be:
      """
      100
      """

  @require-wp-5.2 @require-mysql
  Scenario: Export and import a directory of files with .wxr and .xml extensions.
    Given a WP install
    And I run `mkdir export`
    And I run `wp site empty --yes`
    And I run `wp post generate --count=1`
    And I run `wp post generate --post_type=page --count=1`

    When I run `wp post list --post_type=post,page --format=count`
    Then STDOUT should be:
      """
      2
      """

    When I run `wp export --dir=export --post_type=post --filename_format={site}.wordpress.{date}.{n}.xml`
    Then STDOUT should not be empty
    When I run `wp export --dir=export --post_type=page --filename_format={site}.wordpress.{date}.{n}.wxr`
    Then STDOUT should not be empty

    When I run `wp site empty --yes`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=post,page --format=count`
    Then STDOUT should be:
      """
      0
      """

    When I run `find export -type f | wc -l`
    Then STDOUT should contain:
      """
      2
      """

    When I run `wp plugin install wordpress-importer --activate`
    Then STDERR should be empty

    When I run `wp import export --authors=skip --skip=image_resize`
    Then STDOUT should not be empty
    And STDERR should be empty

    When I run `wp post list --post_type=post,page --format=count`
    Then STDOUT should be:
      """
      2
      """

  @require-wp-5.2 @require-mysql
  Scenario: Export and import page and referencing menu item
    Given a WP install
    And I run `wp site empty --yes`
    And I run `wp post generate --count=1`
    And I run `wp post generate --post_type=page --count=1`
    And I run `mkdir export`

    # NOTE: The Hello World page ID is 2.
    When I run `wp menu create "My Menu"`
    And I run `wp menu item add-post my-menu 2`
    And I run `wp menu item list my-menu --format=count`
    Then STDOUT should be:
      """
      1
      """

    When I run `wp export --dir=export`
    Then STDOUT should not be empty

    When I run `wp site empty --yes`
    Then STDOUT should not be empty

    When I run `wp menu create "My Menu"`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=page --format=count`
    Then STDOUT should be:
      """
      0
      """

    When I run `wp post list --post_type=nav_menu_item --format=count`
    Then STDOUT should be:
      """
      0
      """

    When I run `find export -type f | wc -l`
    Then STDOUT should contain:
      """
      1
      """

    When I run `wp plugin install wordpress-importer --activate`
    Then STDERR should not contain:
      """
      Warning:
      """

    When I run `wp import export --authors=skip --skip=image_resize`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=page --format=count`
    Then STDOUT should be:
      """
      1
      """

    When I run `wp post list --post_type=nav_menu_item --format=count`
    Then STDOUT should be:
      """
      1
      """

    When I run `wp menu item list my-menu --fields=object --format=csv`
    Then STDOUT should contain:
      """
      page
      """

    When I run `wp menu item list my-menu --fields=object_id --format=csv`
    Then STDOUT should contain:
      """
      2
      """

  @require-wp-5.2 @require-mysql
  Scenario: Export and import page and referencing menu item in separate files
    Given a WP install
    And I run `wp site empty --yes`
    And I run `wp post generate --count=1`
    And I run `wp post generate --post_type=page --count=1`
    And I run `mkdir export`

    # NOTE: The Hello World page ID is 2.
    When I run `wp menu create "My Menu"`
    And I run `wp menu item add-post my-menu 2`
    And I run `wp menu item list my-menu --format=count`
    Then STDOUT should be:
      """
      1
      """

    When I run `wp export --dir=export --post_type=page --filename_format=0.page.xml`
    And I run `wp export --dir=export --post_type=nav_menu_item --filename_format=1.menu.xml`
    Then STDOUT should not be empty

    When I run `wp site empty --yes`
    Then STDOUT should not be empty

    When I run `wp menu create "My Menu"`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=page --format=count`
    Then STDOUT should be:
      """
      0
      """

    When I run `wp post list --post_type=nav_menu_item --format=count`
    Then STDOUT should be:
      """
      0
      """

    When I run `find export -type f | wc -l`
    Then STDOUT should contain:
      """
      2
      """

    When I run `wp plugin install wordpress-importer --activate`
    Then STDERR should not contain:
      """
      Warning:
      """

    When I run `wp import export --authors=skip --skip=image_resize`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=page --format=count`
    Then STDOUT should be:
      """
      1
      """

    When I run `wp post list --post_type=nav_menu_item --format=count`
    Then STDOUT should be:
      """
      1
      """

    When I run `wp menu item list my-menu --fields=object --format=csv`
    Then STDOUT should contain:
      """
      page
      """

    When I run `wp menu item list my-menu --fields=object_id --format=csv`
    Then STDOUT should contain:
      """
      2
      """

  @require-wp-5.2 @require-mysql
  Scenario: Indicate current file when importing
    Given a WP install
    And I run `wp plugin install --activate wordpress-importer`

    When I run `wp export --filename_format=wordpress.{n}.xml`
    Then save STDOUT 'Writing to file %s' as {EXPORT_FILE}

    When I run `wp site empty --yes`
    Then STDOUT should not be empty

    When I run `wp import {EXPORT_FILE} --authors=skip`
    Then STDOUT should contain:
      """
      (in file wordpress.000.xml)
      """

  @require-wp-5.2
  Scenario: Handling of non-existing files and directories
    Given a WP install
    And I run `wp plugin install --activate wordpress-importer`
    And I run `wp export`
    And save STDOUT 'Writing to file %s' as {EXPORT_FILE}
    And an empty 'empty_test_directory' directory

    When I try `wp import non_existing_relative_file_path.xml --authors=skip`
    Then STDERR should contain:
      """
      Warning:
      """
    And the return code should be 1

    When I try `wp import non_existing_relative_file_path.xml {EXPORT_FILE} --authors=skip`
    Then STDERR should contain:
      """
      Warning:
      """
    And the return code should be 0

    When I try `wp import empty_test_directory --authors=skip`
    Then STDERR should contain:
      """
      Warning:
      """
    And the return code should be 1

    When I try `wp import empty_test_directory non_existing_relative_file_path.xml --authors=skip`
    Then STDERR should contain:
      """
      Warning:
      """
    And the return code should be 1

  @require-wp-5.2 @require-mysql
  Scenario: Rewrite URLs
    Given a WP install

    When I run `wp option get home`
    Then save STDOUT as {HOME}

    When I run `wp site empty --yes`
    And I run `wp post create --post_title='Post with URL' --post_content='<a href={HOME}>Click me</a>' --post_status='publish'`
    And I run `wp post list --post_type=any --format=csv --fields=post_content`
    Then STDOUT should contain:
      """
      {HOME}
      """

    When I run `wp export`
    Then save STDOUT 'Writing to file %s' as {EXPORT_FILE}

    When I run `wp site empty --yes`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=any --format=count`
    Then STDOUT should be:
      """
      0
      """

    When I run `wp plugin install wordpress-importer --activate`
    Then STDERR should not contain:
      """
      Warning:
      """

    When I run `wp option update home https://newsite.com/`
    And I run `wp option update siteurl https://newsite.com`
    And I run `wp --assume-https import {EXPORT_FILE} --authors=skip --rewrite_urls`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=any --format=csv --fields=post_content`
    Then STDOUT should contain:
      """
      https://newsite.com/
      """

  @require-wp-5.2 @require-mysql
  Scenario: Specifying a non-existent importer class produces an error
    Given a WP install
    And I run `wp plugin install wordpress-importer --activate`

    When I run `wp export`
    Then save STDOUT 'Writing to file %s' as {EXPORT_FILE}

    When I try `wp import {EXPORT_FILE} --authors=skip --importer=NonExistentImporterClass`
    Then STDERR should contain:
      """
      Error: Importer class 'NonExistentImporterClass' does not exist.
      """
    And the return code should be 1

  @require-wp-5.2 @require-mysql
  Scenario: Specifying an importer class that is not a subclass of WP_Import produces an error
    Given a WP install
    And I run `wp plugin install wordpress-importer --activate`

    When I run `wp export`
    Then save STDOUT 'Writing to file %s' as {EXPORT_FILE}

    When I try `wp import {EXPORT_FILE} --authors=skip --importer=WP_CLI_Command`
    Then STDERR should contain:
      """
      Error: Importer class 'WP_CLI_Command' must be a subclass of WP_Import.
      """
    And the return code should be 1

  @require-wp-5.2 @require-mysql
  Scenario: Specifying a valid custom importer subclass succeeds
    Given a WP install
    And I run `wp plugin install wordpress-importer --activate`
    And a wp-content/mu-plugins/custom-importer.php file:
      """
      <?php
      if ( ! class_exists( 'WP_Importer' ) ) {
        require_once ABSPATH . 'wp-admin/includes/class-wp-importer.php';
      }

      if ( ! class_exists( 'WP_Import' ) ) {
        require_once WP_PLUGIN_DIR . '/wordpress-importer/class-wp-import.php';
      }

      class My_Custom_WP_Import extends WP_Import {}
      """

    When I run `wp export`
    Then save STDOUT 'Writing to file %s' as {EXPORT_FILE}

    When I run `wp site empty --yes`
    Then STDOUT should not be empty

    When I run `wp import {EXPORT_FILE} --authors=skip --importer=My_Custom_WP_Import`
    Then STDOUT should not be empty
    And STDERR should be empty

  @require-wp-5.2 @require-mysql
  Scenario: Import from STDIN
    Given a WP install
    And I run `wp plugin install wordpress-importer --activate`
    And I run `wp site empty --yes`
    And I run `wp post generate --post_type=post --count=2`

    When I run `wp post list --post_type=post --format=count`
    Then STDOUT should be:
      """
      2
      """

    When I run `wp export`
    Then save STDOUT 'Writing to file %s' as {EXPORT_FILE}

    When I run `wp site empty --yes`
    Then STDOUT should not be empty

    When I run `wp post list --post_type=post --format=count`
    Then STDOUT should be:
      """
      0
      """

    When I run `cat {EXPORT_FILE} | wp import - --authors=skip`
    Then STDOUT should contain:
      """
      Starting the import process...
      """
    And STDOUT should contain:
      """
      Finished importing from 'STDIN' file.
      """
    And STDERR should be empty

    When I run `wp post list --post_type=post --format=count`
    Then STDOUT should be:
      """
      2
      """

  @require-wp-5.2 @require-mysql
  Scenario: Import from a URL
    Given a WP install
    And I run `wp plugin install wordpress-importer --activate`

    When I run `wp import https://raw.githubusercontent.com/WordPress/theme-test-data/b47acf980696897936265182cb684dca648476c7/theme-preview.xml --authors=skip`
    Then STDOUT should contain:
      """
      Starting the import process...
      """
    And STDOUT should contain:
      """
      Downloading 'https://raw.githubusercontent.com/WordPress/theme-test-data/b47acf980696897936265182cb684dca648476c7/theme-preview.xml'...
      """
    And STDOUT should contain:
      """
      Finished importing from 'https://raw.githubusercontent.com/WordPress/theme-test-data/b47acf980696897936265182cb684dca648476c7/theme-preview.xml' file.
      """
    And STDERR should be empty

  @require-wp-5.2 @require-mysql
  Scenario: Import attachments from a local source directory
    Given a WP install
    And I run `wp plugin install wordpress-importer --activate`
    And I run `mkdir sources`
    And I run `php -r "file_put_contents('sources/test.png', base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='));"`
    And a wxr-with-attachment.xml file:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <rss version="2.0"
        xmlns:excerpt="http://wordpress.org/export/1.2/excerpt/"
        xmlns:content="http://purl.org/rss/1.0/modules/content/"
        xmlns:wfw="http://wellformedweb.org/CommentAPI/"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:wp="http://wordpress.org/export/1.2/">
        <channel>
          <title>Test Site</title>
          <link>http://example.com</link>
          <description>Just another WordPress site</description>
          <wp:wxr_version>1.2</wp:wxr_version>
          <wp:base_site_url>http://example.com</wp:base_site_url>
          <wp:base_blog_url>http://example.com</wp:base_blog_url>
          <item>
            <title>test.png</title>
            <link>http://example.com/?attachment_id=1</link>
            <pubDate>Mon, 01 Jan 2024 00:00:00 +0000</pubDate>
            <dc:creator>admin</dc:creator>
            <guid isPermaLink="false">http://example.com/wp-content/uploads/2024/01/test.png</guid>
            <content:encoded><![CDATA[]]></content:encoded>
            <excerpt:encoded><![CDATA[]]></excerpt:encoded>
            <wp:post_id>1</wp:post_id>
            <wp:post_date>2024-01-01 00:00:00</wp:post_date>
            <wp:post_date_gmt>2024-01-01 00:00:00</wp:post_date_gmt>
            <wp:post_modified>2024-01-01 00:00:00</wp:post_modified>
            <wp:post_modified_gmt>2024-01-01 00:00:00</wp:post_modified_gmt>
            <wp:comment_status>open</wp:comment_status>
            <wp:ping_status>closed</wp:ping_status>
            <wp:post_name>test</wp:post_name>
            <wp:status>inherit</wp:status>
            <wp:post_parent>0</wp:post_parent>
            <wp:menu_order>0</wp:menu_order>
            <wp:post_type>attachment</wp:post_type>
            <wp:post_password></wp:post_password>
            <wp:is_sticky>0</wp:is_sticky>
            <wp:attachment_url>http://example.com/wp-content/uploads/2024/01/test.png</wp:attachment_url>
          </item>
        </channel>
      </rss>
      """

    When I run `wp import wxr-with-attachment.xml --authors=skip --source-dir=sources`
    Then STDOUT should contain:
      """
      -- Using local file for 'http://example.com/wp-content/uploads/2024/01/test.png'.
      """
    And STDERR should be empty

    When I run `wp post list --post_type=attachment --format=count`
    Then STDOUT should be:
      """
      1
      """

