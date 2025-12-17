<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn dyn exslt">

  <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>


  <!--
      # check the following rules:
      #   1. all tables
      #      1.1 all fields should have domain types
      #      1.2 tablespace name should match schema name
      #      1.3 schema name should match schema name
      #      1.4 schema and tablespace name of tables should not be empty
      #   2. dim (dimension) tables
      #      2.1 it should have a primary key of one id_type
      #      2.2 it should have a unique key of one text_type
      #      2.3 it should have a valid_from field if historisation is active
      #                        no valid_from field if historisation is not active
      #   3. fact tables
      #      3.1 it shoud have a primary key of a date_type and at least one id_type
      #      3.2 it shoud have no unique key
      #      3.3 each primary key field should reference the primary key of a dim table
      #   4. hist tables
      #      4.1 it should have a primary key of one id_type and valid_from field of date_type
      #      4.2 it should have no unique key
      #      4.3 it should have a valid_to field of date_type
    -->
  
  <xsl:param name="projectconfig"/>

  <xsl:param name="historisation"/>
  
  <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>

  <xsl:variable name="d">
    <xsl:text>:</xsl:text>
  </xsl:variable>

  <xsl:variable name="k">
    <xsl:text>,</xsl:text>
  </xsl:variable>

  <xsl:variable name="s">
    <xsl:text>.</xsl:text>
  </xsl:variable>

  <xsl:include href="functions.xslt"/>

  <fcn:function name="fcn:count-lines">
    <xsl:param name="strg"/>
    <xsl:param name="target" select="$nl"/>
    <xsl:variable name="first" select="substring-before($strg,$nl)"/>
    <xsl:variable name="rest" select="substring-after($strg,$nl)"/>
    <fcn:result>
      <xsl:choose>
        <xsl:when test="$strg = ''">
          <xsl:value-of select="0"/>
        </xsl:when>
        <xsl:when test="contains($first,$target) or $target = $nl">
          <xsl:value-of select="1 + fcn:count-lines($rest,$target)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:count-lines($rest,$target)"/>
        </xsl:otherwise>
      </xsl:choose>
    </fcn:result>
  </fcn:function>
  

  <fcn:function name="fcn:filter-lines">
    <xsl:param name="strg"/>
    <xsl:param name="filter"/>
    <xsl:variable name="first" select="substring-before($strg,$nl)"/>
    <xsl:variable name="rest" select="substring-after($strg,$nl)"/>
    <fcn:result>
      <xsl:if test="contains($first,$filter)">
        <xsl:value-of select="concat($first,$nl)"/>
      </xsl:if>
      <xsl:if test="string-length($rest) &gt; 0">
        <xsl:value-of select="fcn:filter-lines($rest,$filter)"/>
      </xsl:if>
    </fcn:result>
  </fcn:function>
  

  <fcn:function name="fcn:type-of">
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:param name="column"/>
    <xsl:param name="trace" select="0"/>
    <xsl:variable name="result">
      <xsl:value-of select="//table[@name = $table and @schema = $schema]//column[@name = $column]/@type"/>
    </xsl:variable>
    <xsl:if test="$trace != 0">
      <xsl:message terminate="no">
        <xsl:value-of select="concat('type-of(',$schema,$k,$table,$k,$column,')=',$result,$nl)"/>
      </xsl:message>
    </xsl:if>
    <fcn:result>
      <xsl:value-of select="$result"/>
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:get-nth-element">
    <xsl:param name="strg"/>
    <xsl:param name="n"/>
    <xsl:param name="delim"/>
    <fcn:result>
      <xsl:choose>
        <xsl:when test="not(contains($strg,$delim))">
          <xsl:value-of select="$strg"/>
        </xsl:when>
         <xsl:when test="$n = 1">
          <xsl:value-of select="substring-before($strg,$delim)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:get-nth-element(substring-after($strg,$delim), $n - 1, $delim)"/>
        </xsl:otherwise>
      </xsl:choose>
    </fcn:result>
  </fcn:function>
  
  

  <xsl:variable name="base-schema" select="document($projectconfig)/config/schemaconf[@name = 'base']/@value"/>
  <xsl:variable name="dim-schema"  select="document($projectconfig)/config/schemaconf[@name = 'dim' ]/@value"/>
  <xsl:variable name="fact-schema" select="document($projectconfig)/config/schemaconf[@name = 'fact']/@value"/>
  <xsl:variable name="hist-schema" select="document($projectconfig)/config/schemaconf[@name = 'hist']/@value"/>

  <xsl:variable name="valid-from"  select="document($projectconfig)/config/columnconf[@name = 'valid-from']/@value"/>
  <xsl:variable name="valid-to"    select="document($projectconfig)/config/columnconf[@name = 'valid-to'  ]/@value"/>

  
  <xsl:template match="model">
    <xsl:variable name="errors">
      <xsl:apply-templates select="tables/table"            mode="rule_1_1"/>
      <xsl:apply-templates select="tablespaces/tablespace"  mode="rule_1_2"/>
      <xsl:apply-templates select="schemas/schema"          mode="rule_1_3"/>
      <xsl:apply-templates select="tables/table"            mode="rule_1_4"/>

      <xsl:apply-templates select="tables/table[@schema = $dim-schema]" mode="rule_2_1"/>
      <xsl:apply-templates select="tables/table[@schema = $dim-schema]" mode="rule_2_2"/>
      <xsl:apply-templates select="tables/table[@schema = $dim-schema]" mode="rule_2_3"/>

      <xsl:apply-templates select="tables/table[@schema = $fact-schema]" mode="rule_3_1"/>
      <xsl:apply-templates select="tables/table[@schema = $fact-schema]" mode="rule_3_2"/>
      <xsl:apply-templates select="tables/table[@schema = $fact-schema]" mode="rule_3_3"/>
      
      <xsl:if test="$historisation = 'true'">
        <xsl:apply-templates select="tables/table[@schema = $hist-schema]" mode="rule_4_1"/>
        <xsl:apply-templates select="tables/table[@schema = $hist-schema]" mode="rule_4_2"/>
        <xsl:apply-templates select="tables/table[@schema = $hist-schema]" mode="rule_4_3"/>
      </xsl:if>

    </xsl:variable>
    
    <xsl:variable name="lines-count" select="fcn:count-lines($errors)"/> 
    <xsl:variable name="warning-count" select="fcn:count-lines($errors,':WARNING:')"/> 
    <xsl:variable name="error-count" select="fcn:count-lines($errors,':ERROR:')"/> 

    <xsl:value-of select="concat('historisation: ',$historisation,$nl)"/>
    <xsl:value-of select="concat('rules checked: ',$lines-count,$nl)"/>
    <xsl:value-of select="concat('warnings found: ',$warning-count,$nl)"/>
    <xsl:value-of select="concat('errors found: ',$error-count,$nl)"/>
    <xsl:value-of select="$errors"/>
    <xsl:message terminate="no">
      <xsl:value-of select="concat('historisation: ',$historisation,$nl)"/>
      <xsl:value-of select="concat('rules checked: ',$lines-count,$nl)"/>
      <xsl:value-of select="concat('warnings found: ',$warning-count,$nl)"/>
      <xsl:value-of select="concat('errors found: ',$error-count,$nl)"/>
      <xsl:value-of select="fcn:filter-lines($errors,':ERROR:')"/>
    </xsl:message>
  </xsl:template>

  
  <xsl:template match="table" mode="rule_1_1">
    <xsl:variable name="table" select="@name" />
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="errors">
      <xsl:apply-templates select="columns/column"  mode="rule_1_1">
        <xsl:with-param name="schema" select="$schema"/>
        <xsl:with-param name="table" select="$table"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$errors != ''">
        <xsl:value-of select="$errors"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('rule_1_1:OK:',$schema,$s,$table,$nl)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="column" mode="rule_1_1">
    <xsl:param name="table"/>
    <xsl:param name="schema"/>
    <xsl:variable name="column" select="@name" />
    <xsl:variable name="type" select="@type" />
    <xsl:variable name="ref-type" select="/model/domains/domain[@name = $type]/@type"/>
    <xsl:variable name="missing-ref-type" select="concat('missing ref-type for type ',$type)"/>
    <xsl:if test="string-length($ref-type) = 0">
      <xsl:value-of select="concat('rule_1_1:ERROR:',$schema,$s,$table,$s,$column,$d,$missing-ref-type,$nl)"/>
    </xsl:if>
  </xsl:template>


  <xsl:template match="tablespace" mode="rule_1_2">
    <xsl:variable name="tablespace" select="@name"/>
    <xsl:variable name="schema" select="//schema[@name = $tablespace]/@name"/>
    <xsl:variable name="missing" select="concat('missing schema for tablespace ',$tablespace)"/>
    <xsl:choose>
      <xsl:when test="string-length($schema) = 0">
        <xsl:value-of select="concat('rule_1_2:ERROR:',$missing,$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('rule_1_1:OK:',$tablespace,$d,$schema,$nl)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="schema" mode="rule_1_3">
    <xsl:variable name="schema" select="@name"/>
    <xsl:variable name="tablespace" select="//tablespace[@name = $schema]/@name"/>
    <xsl:variable name="missing" select="concat('missing tablespace for schema ',$schema)"/>
    <xsl:choose>
      <xsl:when test="string-length($tablespace) = 0">
        <xsl:value-of select="concat('rule_1_2:ERROR:',$missing,$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('rule_1_1:OK:',$schema,$d,$tablespace,$nl)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template match="table" mode="rule_1_4">
    <xsl:variable name="table" select="@name" />
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="tablespace" select="@tablespace"/>
    <xsl:variable name="missing-schema-name" select="'schema name for table is empty'"/>
    <xsl:variable name="missing-tablespace-name" select="'tablespace name for table is empty'"/>
    <xsl:variable name="unmatched-schema-tablespace-name" select="'schema name and tablespace name for table are different'"/>

    <xsl:choose>
      <xsl:when test="string-length($schema) = 0">
        <xsl:value-of select="concat('rule_1_4:ERROR:',$table,$d,$missing-schema-name,$nl)"/>
      </xsl:when>
      <xsl:when test="string-length($tablespace) = 0">
        <xsl:value-of select="concat('rule_1_4:ERROR:',$table,$d,$missing-tablespace-name,$nl)"/>
      </xsl:when>
      <xsl:when test="$schema != $tablespace">
        <xsl:value-of select="concat('rule_1_4:ERROR:',$table,$d,$unmatched-schema-tablespace-name,$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('rule_1_4:OK:',$table,$d,$schema,$d,$tablespace,$nl)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="table" mode="rule_2_1">
    <xsl:variable name="table" select="@name" />
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="errors">
      <xsl:apply-templates select="primary"  mode="rule_2_1">
        <xsl:with-param name="schema" select="$schema"/>
        <xsl:with-param name="table" select="$table"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$errors != ''">
        <xsl:value-of select="$errors"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('rule_2_1:OK:',$schema,$s,$table,$nl)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="primary" mode="rule_2_1">
    <xsl:param name="table"/>
    <xsl:param name="schema"/>
    <xsl:variable name="primary" select="@name"/>
    <xsl:variable name="primary-count" select="count(key)"/>
    <xsl:variable name="key-errors">
      <xsl:apply-templates select="key"  mode="rule_2_1">
        <xsl:with-param name="schema" select="$schema"/>
        <xsl:with-param name="table" select="$table"/>
        <xsl:with-param name="primary" select="$primary"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$primary-count != 1">
      <xsl:value-of select="concat('rule_2_1',$d,$primary-count,$nl)"/>
    </xsl:if>
    <xsl:value-of select="$key-errors"/>
  </xsl:template>


  <xsl:template match="key" mode="rule_2_1">
    <xsl:param name="table"/>
    <xsl:param name="schema"/>
    <xsl:param name="primary"/>
    <xsl:variable name="column" select="text()"/>
    <xsl:variable name="type" select="fcn:type-of($schema,$table,$column)"/>
    <xsl:variable name="wrong-type" select="concat('type ',$type,' is not id_type')"/>
    <xsl:if test="$type != 'id_type'">
      <xsl:value-of select="concat('rule_2_1:ERROR:',$schema,$s,$table,$s,$column,$d,$primary,$d,$wrong-type,$nl)"/>
    </xsl:if>
  </xsl:template>


  <xsl:template match="table" mode="rule_2_2">
    <xsl:variable name="table" select="@name" />
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="unique-count" select="count(unique)"/>
    <xsl:variable name="missing-unique" select="'no unique key'"/>
    <xsl:variable name="errors">
      <xsl:apply-templates select="unique"  mode="rule_2_2">
        <xsl:with-param name="schema" select="$schema"/>
        <xsl:with-param name="table" select="$table"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$unique-count = 0">
        <xsl:value-of select="concat('rule_2_2:WARNING:',$schema,$s,$table,$d,$missing-unique,$nl)"/>
      </xsl:when>
      <xsl:when test="string-length($errors) != 0">
        <xsl:value-of select="$errors"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('rule_2_2:OK:',$schema,$s,$table,$nl)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="unique" mode="rule_2_2">
    <xsl:param name="table"/>
    <xsl:param name="schema"/>
    <xsl:variable name="unique" select="@name"/>
    <xsl:variable name="unique-count" select="count(key)"/>
    <xsl:variable name="key-errors">
      <xsl:apply-templates select="key"  mode="rule_2_2">
        <xsl:with-param name="schema" select="$schema"/>
        <xsl:with-param name="table" select="$table"/>
        <xsl:with-param name="unique" select="$unique"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$unique-count = 0">
      <xsl:value-of select="concat('rule_2_2:ERROR:',$d,$schema,$d,$table,$d,$unique-count,$nl)"/>
    </xsl:if>
    <xsl:value-of select="$key-errors"/>
  </xsl:template>


  <xsl:template match="key" mode="rule_2_2">
    <xsl:param name="table"/>
    <xsl:param name="schema"/>
    <xsl:param name="unique"/>
    <xsl:variable name="key" select="text()"/>
    <xsl:variable name="type" select="fcn:type-of($schema,$table,$key)"/>

    <xsl:if test="$type != 'text_type' and $type != 'date_type'">
      <xsl:value-of select="concat('rule_2_2:ERROR:',$schema,$d,$table,$d,$key,$d,$unique,$d,$type,$nl)"/>
    </xsl:if>
  </xsl:template>


  <xsl:template match="table" mode="rule_2_3">
    <xsl:variable name="table" select="@name" />
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="column-count" select="count(columns/column[@name = $valid-from])"/>
    <xsl:variable name="missing" select="concat(': missing column ',$valid-from)"/>
    <xsl:variable name="unexpected" select="concat(': found unexpected column ',$valid-from)"/>
    <xsl:choose>
      <xsl:when test="$historisation = 'true'">
        <xsl:choose>
          <xsl:when test="$column-count != 1">
            <xsl:value-of select="concat('rule_2_3:ERROR:',$d,$schema,$s,$table,$d,$column-count,$missing,$nl)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('rule_2_3:OK:',$d,$schema,$s,$table,$d,$column-count,$nl)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$column-count = 1">
            <xsl:value-of select="concat('rule_2_3:ERROR:',$d,$schema,$s,$table,$d,$column-count,$unexpected,$nl)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('rule_2_3:OK:',$d,$schema,$s,$table,$d,$column-count,$nl)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template match="table" mode="rule_3_1">
    <xsl:variable name="table" select="@name" />
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="primary-count" select="count(primary/key)"/>
    <xsl:variable name="errors">
      <xsl:apply-templates select="primary"  mode="rule_3_1">
        <xsl:with-param name="schema" select="$schema"/>
        <xsl:with-param name="table" select="$table"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$primary-count = 0">
        <xsl:value-of select="concat('rule_3_1:OK:',$schema,$s,$table,$d,$primary-count,$nl)"/>
      </xsl:when>
      <xsl:when test="$errors != ''">
        <xsl:value-of select="$errors"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('rule_3_1:OK:',$schema,$s,$table,$nl)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="primary" mode="rule_3_1">
    <xsl:param name="table"/>
    <xsl:param name="schema"/>
    <xsl:variable name="primary" select="@name"/>
    <xsl:variable name="id-primary-count" select="count(key[fcn:type-of($schema,$table,text()) = 'id_type'])"/>
    <xsl:variable name="date-primary-count" select="count(key[fcn:type-of($schema,$table,text()) = 'date_type'])"/>
    <xsl:variable name="id-error" select="'missing id_type primary key'"/>
    <xsl:variable name="date-error" select="concat('wrong date_type primary key, count=',$date-primary-count)"/>
    <xsl:variable name="key-errors">
      <xsl:apply-templates select="key"  mode="rule_3_1">
        <xsl:with-param name="schema" select="$schema"/>
        <xsl:with-param name="table" select="$table"/>
        <xsl:with-param name="primary" select="$primary"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$id-primary-count = 0">
      <xsl:value-of select="concat('rule_3_1:ERROR:',$schema,$d,$table,$d,$id-error,$nl)"/>
    </xsl:if>
    <xsl:if test="$date-primary-count &gt; 1">
      <xsl:value-of select="concat('rule_3_1:ERROR:',$schema,$d,$table,$d,$date-error,$nl)"/>
    </xsl:if>
    <xsl:value-of select="$key-errors"/>
  </xsl:template>


  <xsl:template match="key" mode="rule_3_1">
    <xsl:param name="table"/>
    <xsl:param name="schema"/>
    <xsl:param name="primary"/>
    <xsl:variable name="key" select="text()"/>
    <xsl:variable name="type" select="fcn:type-of($schema,$table,$key)"/>
    <xsl:if test="$type != 'id_type' and $type != 'date_type'">
      <xsl:value-of select="concat('rule_3_1:ERROR:',$schema,$d,$table,$d,$primary,$d,$type,$nl)"/>
    </xsl:if>
  </xsl:template>


  <xsl:template match="table" mode="rule_3_2">
    <xsl:variable name="table" select="@name" />
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="unique-count" select="count(unique/key)"/>
    <xsl:variable name="unique-error" select="concat(' fakt should not have unique key, but found ',$unique-count)"/>
    <xsl:choose>
      <xsl:when test="$unique-count != 0">
        <xsl:value-of select="concat('rule_3_2:WARNING:',$schema,$d,$table,$d,$unique-error,$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('rule_3_2:OK:',$schema,$s,$table,$nl)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



  <xsl:template match="table" mode="rule_3_3">
    <xsl:variable name="table" select="@name" />
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="primary-count" select="count(primary)"/>
    <xsl:variable name="errors">
      <xsl:apply-templates select="primary"  mode="rule_3_3">
        <xsl:with-param name="schema" select="$schema"/>
        <xsl:with-param name="table" select="$table"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$primary-count != 1">
        <xsl:value-of select="concat('rule_3_3:ERROR:',$schema,$s,$table,$d,$primary-count,$nl)"/>
      </xsl:when>
      <xsl:when test="$errors != ''">
        <xsl:value-of select="$errors"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('rule_3_3:OK:',$schema,$s,$table,$nl)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="primary" mode="rule_3_3">
    <xsl:param name="table"/>
    <xsl:param name="schema"/>
    <xsl:variable name="primary" select="@name"/>
    <xsl:variable name="errors">
      <xsl:apply-templates select="key"  mode="rule_3_3">
        <xsl:with-param name="schema" select="$schema"/>
        <xsl:with-param name="table" select="$table"/>
        <xsl:with-param name="primary" select="$primary"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="$errors != ''">
      <xsl:value-of select="$errors"/>
    </xsl:if>
  </xsl:template>


  <xsl:template match="key" mode="rule_3_3">
    <xsl:param name="table"/>
    <xsl:param name="schema"/>
    <xsl:param name="unique"/>
    <xsl:variable name="column" select="text()"/>
    <xsl:variable name="type" select="//table[@name = $table and @schema = $schema]//column[@name = $column]/@type"/>

    <xsl:if test="$type = 'id_type'">
      <xsl:variable name="target">
        <xsl:for-each select="//source[@schema = $schema and @table = $table]/../foreign/key">
          <xsl:if test="text() = $column">
            <xsl:value-of select="concat(../../target/@schema,$d,../../target/@table,$d,text())"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="ref-schema" select="fcn:get-nth-element($target,1,$d)"/>
      <xsl:variable name="ref-table"  select="fcn:get-nth-element($target,2,$d)"/>
      <xsl:variable name="ref-column" select="fcn:get-nth-element($target,3,$d)"/>
      
      <xsl:variable name="ref-pk">
        <xsl:for-each select="//table[@schema = $ref-schema and @name = $ref-table]/primary/key">
          <xsl:value-of select="concat($d,text(),$d)"/>
        </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="pk-error"
                    select="concat('referenced column is not pk of target table',$d,
                            $ref-schema,$s,$ref-table,$s,$ref-column)"/> 
      <xsl:if test="not(contains($ref-pk,$column))">
        <xsl:value-of select="concat('rule_3_3:ERROR:',$schema,$d,$table,$s,$column,$d,$pk-error,$nl)"/>
      </xsl:if>
    </xsl:if>    
  </xsl:template>


  <xsl:template match="table" mode="rule_4_1">
    <xsl:variable name="table" select="@name" />
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="primary-count" select="count(primary)"/>
    <xsl:variable name="primary-key-count" select="count(primary/key)"/>
    <xsl:choose>
      <xsl:when test="$primary-count != 1 or $primary-key-count != 2">
        <xsl:variable name="invalid-primary"
                      select="concat('invalid primary key (',$primary-count,$d,$primary-key-count,')')"/>
        <xsl:value-of select="concat('rule_4_1:ERROR:',$schema,$d,$table,$s,$column,$d,$pk-error,$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="errors">
          <xsl:apply-templates select="primary"  mode="rule_4_1">
            <xsl:with-param name="schema" select="$schema"/>
            <xsl:with-param name="table" select="$table"/>
          </xsl:apply-templates>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="string-length($errors) != 0">
            <xsl:value-of select="$errors"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('rule_4_1:OK:',$schema,$d,$table,$nl)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="primary" mode="rule_4_1">
    <xsl:param name="table"/>
    <xsl:param name="schema"/>
    <xsl:variable name="column-1" select="key[position() = 1]" />
    <xsl:variable name="column-2" select="key[position() = 2]" />
    <xsl:variable name="type-1"
                  select="//tables[@name = $table and @schema = $schema]//column[@name = $column-1]/@type"/>
    <xsl:variable name="type-2"
                  select="//tables[@name = $table and @schema = $schema]//column[@name = $column-2]/@type"/>
    <xsl:variable name="error-1"
                  select="concat('wrong type ',$type-1,' for 1. primary key column')"/>
    <xsl:variable name="error-2"
                  select="concat('wrong type ',$type-1,' for 2. primary key column')"/>
    <xsl:if test="$type-1 != 'date-type'">
      <xsl:value-of select="concat('rule_4_1:ERROR:',$schema,$s,$table,$s,$column-1,$error-1,$nl)"/>
    </xsl:if>
    <xsl:if test="$type-2 != 'id-type'">
      <xsl:value-of select="concat('rule_4_1:ERROR:',$schema,$s,$table,$s,$column-1,$error-1,$nl)"/>
    </xsl:if>
  </xsl:template>

  
  <xsl:template match="table" mode="rule_4_2">
    <xsl:variable name="table" select="@name" />
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="unique" select="unique/@name"/>
    <xsl:variable name="unique-count" select="count(unique)"/>
    <xsl:variable name="unique-error" select="concat('found unique key ',$unique)"/>
    <xsl:choose>
      <xsl:when test="$unique-count != 0">
        <xsl:value-of select="concat('rule_4_2:ERROR:',$schema,$s,$table,$d,$unique-error,$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('rule_4_2:OK:',$schema,$d,$table,$nl)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template match="table" mode="rule_4_3">
    <xsl:variable name="table" select="@name" />
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="valid-to-count" select="count(.//column[@name = $valid-to])"/>
    <xsl:choose>
      <xsl:when test="$valid-to-count != 1">
        <xsl:variable name="count-error" select="concat('table has ',$valid-to-count,' ',$valid-to,' columns')"/>
        <xsl:value-of select="concat('rule_4_4:ERROR:',$schema,$s,$table,$d,$count-error,$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="errors">
          <xsl:apply-templates select="column[@name = $valid-to]">
            <xsl:with-param name="schema" select="$schema"/>
            <xsl:with-param name="table" select="$table"/>
          </xsl:apply-templates>
        </xsl:variable>      
        <xsl:choose>
          <xsl:when test="string-length($errors) != 0">
            <xsl:value-of select="$errors"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('rule_4_4:OK:',$schema,$s,$table,$nl)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template match="column" mode="rule_4_3">
    <xsl:param name="table"/>
    <xsl:param name="schema"/>
    <xsl:variable name="column" select="@name"/>
    <xsl:variable name="type" select="@type"/>
    <xsl:if test="$type != 'date_type'">
      <xsl:variable name="key-error" select="concat('column ',$column,' has invalid data type ',$type)"/>
      <xsl:value-of select="concat('rule_4_4:ERROR:',$schema,$s,$table,$d,$key-error,$nl)"/>
    </xsl:if>
  </xsl:template>


  
</xsl:stylesheet> 
