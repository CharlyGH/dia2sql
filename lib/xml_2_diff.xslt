<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn dyn"
                >

  <xsl:output method="xml"
              omit-xml-declaration="no" 
              indent="yes"
              version="1.0"
              doctype-system="delta.dtd"
              />

  <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>

  <xsl:include href="functions.xslt"/>

  <xsl:param name="oldfile"/>
  
  <xsl:param name="newfile"/>
  

  <fcn:function name="fcn:get-action">
    <xsl:param name="old-text"/>
    <xsl:param name="new-text"/>
    <fcn:result>
      <xsl:choose>
        <xsl:when test="$old-text = ''">
          <xsl:value-of select="'create'"/>
        </xsl:when>
        <xsl:when test="$old-text != $new-text">
          <xsl:value-of select="'alter'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'nop'"/>
        </xsl:otherwise>
      </xsl:choose>
    </fcn:result>
  </fcn:function>
  

  <fcn:function name="fcn:check-comment">
    <xsl:param name="new-comment"/>
    <xsl:param name="old-comment"/>
    <xsl:param name="old-name"/>
    <fcn:result>
      <xsl:choose>
        <xsl:when test="string-length($new-comment) != 0 and string-length($old-name) != 0 
                        and ($new-comment != $old-comment or string-length($old-comment) = 0)">
          <xsl:value-of select="'true'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'false'"/>
        </xsl:otherwise>
      </xsl:choose>
    </fcn:result>
  </fcn:function>
  

  <xsl:template match="delta">
    <xsl:variable name="old-project" select="document($oldfile)/model/@project"/>
    <xsl:variable name="new-project" select="document($newfile)/model/@project"/>
    <xsl:variable name="old-version" select="document($oldfile)/model/@version"/>
    <xsl:variable name="new-version" select="document($newfile)/model/@version"/>

    <xsl:if test="$old-project != $new-project">
      <xsl:message terminate="yes">
        <xsl:value-of select="concat('project names:',$old-project,' and ', $new-project,' do not match',$nl)"/>
      </xsl:message>
    </xsl:if>
    <xsl:if test="$old-version = $new-version">
      <xsl:message terminate="yes">
        <xsl:value-of select="concat('project versions are equal :',$old-version,$nl)"/>
      </xsl:message>
    </xsl:if>
    
    <xsl:element name="delta">
      <xsl:attribute name="project">
        <xsl:value-of select="$old-project"/>
      </xsl:attribute>
      <xsl:attribute name="old-version">
        <xsl:value-of select="$old-version"/>
      </xsl:attribute>
      <xsl:attribute name="new-version">
        <xsl:value-of select="$new-version"/>
      </xsl:attribute>

      <xsl:variable name="old-tablespaces">
        <xsl:apply-templates select="document($oldfile)//tablespace" mode="astext"/>
      </xsl:variable>
      <xsl:variable name="new-tablespaces">
        <xsl:apply-templates select="document($newfile)//tablespace" mode="astext"/>
      </xsl:variable>

      <xsl:if test="$old-tablespaces != $new-tablespaces">
        <xsl:element name="tablespaces">
          <xsl:apply-templates select="document($newfile)//tablespace" mode="asxml"/>
        </xsl:element>
      </xsl:if>
    
      <xsl:variable name="old-schemas">
        <xsl:apply-templates select="document($oldfile)//schema" mode="astext"/>
      </xsl:variable>
      <xsl:variable name="new-schemas">
        <xsl:apply-templates select="document($newfile)//schema" mode="astext"/>
      </xsl:variable>
      <xsl:if test="$old-schemas != $new-schemas">
        <xsl:element name="schemas">
          <xsl:apply-templates select="document($newfile)//schema" mode="asxml"/>
        </xsl:element>
      </xsl:if>
    
      <xsl:variable name="old-domains">
        <xsl:apply-templates select="document($oldfile)//domain" mode="astext"/>
      </xsl:variable>
      <xsl:variable name="new-domains">
        <xsl:apply-templates select="document($newfile)//domain" mode="astext"/>
      </xsl:variable>
      <xsl:if test="$old-domains != $new-domains">
        <xsl:element name="domains">
          <xsl:apply-templates select="document($newfile)//domain" mode="asxml"/>
        </xsl:element>
      </xsl:if>
    
      <xsl:variable name="old-sequences">
        <xsl:apply-templates select="document($oldfile)//sequence" mode="astext"/>
      </xsl:variable>
      <xsl:variable name="new-sequences">
        <xsl:apply-templates select="document($newfile)//sequence" mode="astext"/>
      </xsl:variable>
      <xsl:if test="$old-sequences != $new-sequences">
        <xsl:element name="sequences">
          <xsl:apply-templates select="document($newfile)//sequence" mode="asxml"/>
        </xsl:element>
      </xsl:if>
    
      <xsl:variable name="old-tables">
        <xsl:apply-templates select="document($oldfile)//table" mode="astext"/>
      </xsl:variable>
      <xsl:variable name="new-tables">
        <xsl:apply-templates select="document($newfile)//table" mode="astext"/>
      </xsl:variable>
      <xsl:if test="$old-tables != $new-tables">
        <xsl:element name="tables">
          <xsl:apply-templates select="document($newfile)//table" mode="asxml"/>
        </xsl:element>
      </xsl:if>

      <xsl:variable name="old-references">
        <xsl:apply-templates select="document($oldfile)//reference" mode="astext"/>
      </xsl:variable>
      <xsl:variable name="new-references">
        <xsl:apply-templates select="document($newfile)//reference" mode="astext"/>
      </xsl:variable>
      <xsl:if test="$old-references != $new-references">
        <xsl:element name="references">
          <xsl:apply-templates select="document($newfile)//reference" mode="asxml"/>
        </xsl:element>
      </xsl:if>

      <xsl:element name="informations">
        <xsl:apply-templates select="document($newfile)/model" mode="comment"/>
      </xsl:element>

      <xsl:call-template name="metadata"/>

    </xsl:element>
  </xsl:template>


  <xsl:template name="metadata">
    <xsl:variable name="schema"  select="document($newfile)//metadata/table/@schema"/>
    <xsl:variable name="table"   select="document($newfile)//metadata/table/@name"/>
    <xsl:variable name="version" select="document($newfile)//metadata/insert/version/text()"/>

    <xsl:element name="metadata">
      <xsl:element name="update">
        <xsl:attribute name="schema">
          <xsl:value-of select="$schema"/>
        </xsl:attribute>
        <xsl:attribute name="table">
          <xsl:value-of select="$table"/>
        </xsl:attribute>
        <xsl:element name="version">
          <xsl:value-of select="$version"/>
        </xsl:element>
      </xsl:element>
      <xsl:element name="commit"/>
    </xsl:element>
  </xsl:template>
  

  <xsl:template match="tablespace" mode="asxml">
    <xsl:variable name="tablespace" select="@name"/>
    <xsl:variable name="old-count"
                  select="count(document($oldfile)//tablespace[@name = $tablespace])"/>
    <xsl:variable name="old-tablespace">
      <xsl:apply-templates select="document($oldfile)//tablespace[@name = $tablespace]" mode="astext"/>
    </xsl:variable>
    <xsl:variable name="new-tablespace">
      <xsl:apply-templates select="document($newfile)//tablespace[@name = $tablespace]" mode="astext"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$old-count = 0">
        <xsl:copy-of select="."/>
      </xsl:when>
      <xsl:when test="$old-location != $new-location">
        <xsl:message terminate="yes">
          <xsl:value-of select="concat('cannot alter location for tablespace ',$tablespace,$nl)"/>
        </xsl:message>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template match="schema" mode="asxml">
    <xsl:variable name="schema" select="@name"/>
    <xsl:variable name="old-count"
                  select="count(document($oldfile)//schema[@name = $schema])"/>
    <xsl:choose>
      <xsl:when test="$old-count = 0">
        <xsl:copy-of select="."/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  
  <xsl:template match="domain" mode="asxml">
    <xsl:variable name="domain" select="@name"/>
    <xsl:variable name="old-count"
                  select="count(document($oldfile)//domain[@name = $domain])"/>
    <xsl:variable name="old-domain">
      <xsl:apply-templates select="document($oldfile)//domain[@name = $domain]" mode="astext"/>
    </xsl:variable>
    <xsl:variable name="new-domain">
      <xsl:apply-templates select="document($newfile)//domain[@name = $domain]" mode="astext"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$old-count = 0">
        <xsl:copy-of select="."/>
      </xsl:when>
      <xsl:when test="$old-domain != $new-domain">
        <xsl:element name="domain">
          <xsl:attribute name="name">
            <xsl:value-of select="$domain"/>
          </xsl:attribute>
          <xsl:attribute name="schema">
            <xsl:value-of select="@schema"/>
          </xsl:attribute>
          <xsl:attribute name="type">
            <xsl:value-of select="@type"/>
          </xsl:attribute>
          <xsl:attribute name="nullable">
            <xsl:value-of select="@nullable"/>
          </xsl:attribute>
          <xsl:attribute name="action">
            <xsl:value-of select="'alter'"/>
          </xsl:attribute>
          <xsl:variable name="new-size"
                        select="document($newfile)//domain[@name = $domain]/size/text()"/>
          <xsl:if test="string-length($new-size) != 0">
            <xsl:element name="size">
              <xsl:value-of select="$new-size"/>
            </xsl:element>
          </xsl:if>
          <xsl:variable name="new-default"
                        select="document($newfile)//domain[@name = $domain]/default/text()"/>
          <xsl:if test="string-length($new-default) != 0">
            <xsl:element name="default">
              <xsl:value-of select="$new-default"/>
            </xsl:element>
          </xsl:if>
          <xsl:variable name="new-constraint"
                        select="document($newfile)//domain[@name = $domain]/constraint/node()"/>
          <xsl:if test="string-length($new-constraint) != 0">
            <xsl:copy-of select="document($newfile)//domain[@name = $domain]/constraint"/>
          </xsl:if>
        </xsl:element>
      </xsl:when>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="table" mode="asxml">
    <xsl:variable name="table"  select="@name"/>
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="old-count"
                  select="count(document($oldfile)//table[@name = $table and @schema = $schema])"/>
    <xsl:variable name="old-table">
      <xsl:apply-templates select="document($oldfile)//table[@name = $table and @schema = $schema]" mode="astext"/>
    </xsl:variable>
    <xsl:variable name="new-table">
      <xsl:apply-templates select="document($newfile)//table[@name = $table and @schema = $schema]" mode="astext"/>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$old-count = 0">
        <xsl:copy-of select="."/>
      </xsl:when>
      <xsl:when test="$old-table != $new-table">
        <xsl:element name="table">
          <xsl:attribute name="name">
            <xsl:value-of select="@name"/>
          </xsl:attribute>
          <xsl:attribute name="schema">
            <xsl:value-of select="@schema"/>
          </xsl:attribute>
          <xsl:attribute name="tablespace">
            <xsl:value-of select="@tablespace"/>
          </xsl:attribute>
          <xsl:attribute name="auto">
            <xsl:value-of select="@auto"/>
          </xsl:attribute>
          <xsl:attribute name="action">
            <xsl:value-of select="'alter'"/>
          </xsl:attribute>
          <xsl:variable name="old-columns">
            <xsl:apply-templates select="document($oldfile)//table[@name = $table and @schema = $schema]//column"
                                 mode="astext"/>
          </xsl:variable>
          <xsl:variable name="new-columns">
            <xsl:apply-templates select="document($newfile)//table[@name = $table and @schema = $schema]//column"
                                 mode="astext"/>
          </xsl:variable>
          <xsl:if test="$old-columns != $new-columns">
            <xsl:element name="columns">
              <xsl:apply-templates select="columns/column"
                                   mode="asxml">
                <xsl:with-param name="table" select="$table"/>
                <xsl:with-param name="schema" select="$schema"/>
              </xsl:apply-templates>
            </xsl:element>
          </xsl:if>
        </xsl:element>
      </xsl:when>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="column" mode="asxml">
    <xsl:param name="table"/>
    <xsl:param name="schema"/>
    <xsl:variable name="column"  select="@name"/>
    <xsl:variable name="old-count"
                  select="count(document($oldfile)//table[@name = $table
                          and @schema = $schema]//column[@name = $column])"/>
    <xsl:variable name="old-column">
      <xsl:apply-templates select="document($oldfile)//table[@name = $table
                                   and @schema = $schema]//column[@name = $column]"
                           mode="astext"/>
    </xsl:variable>
    <xsl:variable name="new-column">
      <xsl:apply-templates select="document($newfile)//table[@name = $table
                                   and @schema = $schema]//column[@name = $column]"
                           mode="astext"/>
    </xsl:variable>
    <xsl:variable name="new-size"
                  select="document($newfile)//table[@name = $table
                          and @schema = $schema]//column[@name = $column]/size/text()"/>
    <xsl:variable name="old-size"
                  select="document($newfile)//table[@name = $table
                          and @schema = $schema]//column[@name = $column]/size/text()"/>
    <xsl:variable name="new-default"
                  select="document($newfile)//table[@name = $table
                          and @schema = $schema]//column[@name = $column]/default/text()"/>
    <xsl:variable name="old-default"
                  select="document($newfile)//table[@name = $table
                          and @schema = $schema]//column[@name = $column]/default/text()"/>
    <xsl:choose>
      <xsl:when test="$old-count = 0">
        <xsl:copy-of select="."/>
      </xsl:when>
      <xsl:when test="$old-column != $new-column">
        <xsl:element name="column">
          <xsl:attribute name="name">
            <xsl:value-of select="@name"/>
          </xsl:attribute>
          <xsl:attribute name="type">
            <xsl:value-of select="@type"/>
          </xsl:attribute>
          <xsl:attribute name="nullable">
            <xsl:value-of select="@nullable"/>
          </xsl:attribute>
          <xsl:attribute name="auto">
            <xsl:value-of select="@auto"/>
          </xsl:attribute>
          <xsl:attribute name="action">
            <xsl:value-of select="'alter'"/>
          </xsl:attribute>
          <xsl:if test="string-length($new-size) != 0 and $new-size != $old-size">
            <xsl:element name="size">
              <xsl:value-of select="$new-size"/>
            </xsl:element>
          </xsl:if>
          <xsl:if test="string-length($new-default) != 0 and $new-default != $old-default">
            <xsl:element name="default">
              <xsl:value-of select="$new-default"/>
            </xsl:element>
          </xsl:if>
        </xsl:element>
      </xsl:when>
    </xsl:choose>
  </xsl:template>


  
  <xsl:template match="reference" mode="asxml">
    <xsl:variable name="reference" select="@name"/>
    <xsl:variable name="old-count"
                  select="count(document($oldfile)//reference[@name = $reference])"/>
    <xsl:variable name="old-reference">
      <xsl:apply-templates select="document($oldfile)//reference[@name = $reference]" mode="astext"/>
    </xsl:variable>
    <xsl:variable name="new-reference">
      <xsl:apply-templates select="document($newfile)//reference[@name = $reference]" mode="astext"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$old-count = 0">
        <xsl:copy-of select="."/>
      </xsl:when>
      <xsl:when test="$old-reference != $new-reference">
        <xsl:element name="reference">
          <xsl:attribute name="name">
            <xsl:value-of select="$reference"/>
          </xsl:attribute>
          <xsl:attribute name="action">
            <xsl:value-of select="'alter'"/>
          </xsl:attribute>
          <xsl:copy-of select="document($newfile)//reference[@name = $reference]/source"/>
          <xsl:copy-of select="document($newfile)//reference[@name = $reference]/target"/>
          <xsl:copy-of select="document($newfile)//reference[@name = $reference]/foreign"/>
        </xsl:element>
      </xsl:when>
    </xsl:choose>

  </xsl:template>


  
  <!-- helper templates, mode=astext -->


  <xsl:template match="location | comment | size | default | value | statement | function | column-list" mode="astext">
    <xsl:value-of select="concat(node(),'#',text(),nll)"/>
  </xsl:template>


  <xsl:template match="tablespace" mode="astext">
    <xsl:value-of select="concat(node(),'#',@name,$nl)"/>
    <xsl:apply-templates select="location" mode="astext"/>
  </xsl:template>

  
  <xsl:template match="schema" mode="astext">
    <xsl:value-of select="concat(node(),'#',@name,$nl)"/>
  </xsl:template>

  
  <xsl:template match="domain" mode="astext">
    <xsl:value-of select="concat(node(),'#',@name,'#',@schema,'#',@type,'#',@nullable,$nl)"/>
    <xsl:apply-templates select="size"        mode="astext"/>
    <xsl:apply-templates select="default"     mode="astext"/>
    <xsl:apply-templates select="constraint"  mode="astext"/>
  </xsl:template>

  <xsl:template match="constraint" mode="astext">
    <xsl:value-of select="concat(node(),'#',@name,'#',@type,$nl)"/>
    <xsl:apply-templates select="value" mode="astext"/>
  </xsl:template>

  
  <xsl:template match="sequence" mode="astext">
    <xsl:value-of select="concat(node(),'#',@name,'#',@schema,'#',@type,'#',$nl)"/>
    <xsl:apply-templates select="config"   mode="astext"/>
  </xsl:template>


  
  <xsl:template match="config" mode="astext">
    <xsl:value-of select="concat(node(),'#',@start,'#',@min,'#',@max,'#',@increment,'#',@cycle,$nl)"/>
  </xsl:template>


  <xsl:template match="table" mode="astext">
    <xsl:value-of select="concat(node(),'#',@name,'#',@schema,'#',@tablespace,'#',@auto,$nl)"/>
    <xsl:apply-templates select="columns/column"    mode="astext"/>
    <xsl:apply-templates select="primary"           mode="astext"/>
    <xsl:apply-templates select="unique"            mode="astext"/>
    <xsl:apply-templates select="triggers/trigger"  mode="astext"/>
  </xsl:template>


  <xsl:template match="column" mode="astext">
    <xsl:value-of select="concat(node(),'#',@name,'#',@type,'#',@nullable,'#',@auto,$nl)"/>
    <xsl:apply-templates select="size"        mode="astext"/>
    <xsl:apply-templates select="default"     mode="astext"/>
    <xsl:apply-templates select="constraint"  mode="astext"/>
  </xsl:template>

  
  <xsl:template match="primary" mode="astext">
    <xsl:value-of select="concat(node(),'#',@name,$nl)"/>
    <xsl:apply-templates select="key"   mode="astext"/>
  </xsl:template>

  
  <xsl:template match="unique" mode="astext">
    <xsl:value-of select="concat(node(),'#',@name,$nl)"/>
    <xsl:apply-templates select="key"   mode="astext"/>
  </xsl:template>

  
  <xsl:template match="trigger" mode="astext">
    <xsl:value-of select="concat(node(),'#',@table-name,'#',@trigger-name,'#',@function-name,$nl)"/>
    <xsl:apply-templates select="definition"  mode="astext"/>
    <xsl:apply-templates select="function"    mode="astext"/>
  </xsl:template>

  
  <xsl:template match="definition" mode="astext">
    <xsl:value-of select="concat(node(),'#',@action,'#',@level,'#',@timing,$nl)"/>
    <xsl:apply-templates select="statement"    mode="astext"/>
    <xsl:apply-templates select="column-list"  mode="astext"/>
  </xsl:template>


  <xsl:template match="reference" mode="astext">
    <xsl:value-of select="concat(node(),'#',@name,$nl)"/>
    <xsl:apply-templates select="source"    mode="astext"/>
    <xsl:apply-templates select="target"    mode="astext"/>
    <xsl:apply-templates select="foreign"   mode="astext"/>
  </xsl:template>


  <xsl:template match="source | target" mode="astext">
    <xsl:value-of select="concat(node(),'#',@schema,'#',@table,$nl)"/>
  </xsl:template>


  <xsl:template match="foreign" mode="astext">
    <xsl:value-of select="concat(node(),$nl)"/>
    <xsl:apply-templates select="key"   mode="astext"/>
  </xsl:template>


  
  <xsl:template match="model" mode="comment">
    <xsl:apply-templates select="tablespaces/tablespace"         mode="comment"/>
    <xsl:apply-templates select="schemas/schema"                 mode="comment"/>
    <xsl:apply-templates select="domains/domain"                 mode="comment"/>
    <xsl:apply-templates select="sequences/sequence"             mode="comment"/>
    <xsl:apply-templates select="tables/table"                   mode="comment"/>
    <xsl:apply-templates select="tables/table/columns/column"    mode="comment"/>
  </xsl:template>


  <xsl:template match="tablespace" mode="comment">
    <xsl:variable name="name" select="@name"/>
    <xsl:variable name="old-comment"
                  select="document($oldfile)//tablespace[@name = $name]/comment/text()"/>
    <xsl:variable name="new-comment"
                  select="document($newfile)//tablespace[@name = $name]/comment/text()"/>
    <xsl:variable name="old-name"
                  select="document($oldfile)//tablespace[@name = $name]/@name"/>
    <xsl:if test="fcn:check-comment($new-comment,$old-comment,$old-name) = 'true'">
      <xsl:element name="information">
        <xsl:attribute name="type">
          <xsl:value-of select="'tablespace'"/>
        </xsl:attribute>
        <xsl:attribute name="name">
          <xsl:value-of select="$name"/>
        </xsl:attribute>
        <xsl:element name="comment">
          <xsl:value-of select="$new-comment"/>
        </xsl:element>
      </xsl:element>
    </xsl:if>
  </xsl:template>


  <xsl:template match="schema" mode="comment">
    <xsl:variable name="name" select="@name"/>
    <xsl:variable name="old-comment"
                  select="document($oldfile)//schema[@name = $name]/comment/text()"/>
    <xsl:variable name="new-comment"
                  select="document($newfile)//schema[@name = $name]/comment/text()"/>
    <xsl:variable name="old-name"
                  select="document($oldfile)//schema[@name = $name]/@name"/>
    <xsl:if test="fcn:check-comment($new-comment,$old-comment,$old-name) = 'true'">
      <xsl:element name="information">
        <xsl:attribute name="type">
          <xsl:value-of select="'schema'"/>
        </xsl:attribute>
        <xsl:attribute name="name">
          <xsl:value-of select="$name"/>
        </xsl:attribute>
        <xsl:element name="comment">
          <xsl:value-of select="$new-comment"/>
        </xsl:element>
      </xsl:element>
    </xsl:if>
  </xsl:template>


  <xsl:template match="domain" mode="comment">
    <xsl:variable name="name" select="@name"/>
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="old-comment"
                  select="document($oldfile)//domain[@name = $name]/comment/text()"/>
    <xsl:variable name="new-comment"
                  select="document($newfile)//domain[@name = $name]/comment/text()"/>
    <xsl:variable name="old-name"
                  select="document($oldfile)//domain[@name = $name]/@name"/>
    <xsl:if test="fcn:check-comment($new-comment,$old-comment,$old-name) = 'true'">
      <xsl:element name="information">
        <xsl:attribute name="type">
          <xsl:value-of select="'domain'"/>
        </xsl:attribute>
        <xsl:attribute name="name">
          <xsl:value-of select="$name"/>
        </xsl:attribute>
        <xsl:attribute name="schema">
          <xsl:value-of select="$schema"/>
        </xsl:attribute>
        <xsl:element name="comment">
          <xsl:value-of select="$new-comment"/>
        </xsl:element>
      </xsl:element>
    </xsl:if>
  </xsl:template>


  <xsl:template match="sequence" mode="comment">
    <xsl:variable name="name" select="@name"/>
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="old-comment"
                  select="document($oldfile)//sequence[@name = $name]/comment/text()"/>
    <xsl:variable name="new-comment"
                  select="document($newfile)//sequence[@name = $name]/comment/text()"/>
    <xsl:variable name="old-name"
                  select="document($oldfile)//sequence[@name = $name]/@name"/>
    <xsl:if test="fcn:check-comment($new-comment,$old-comment,$old-name) = 'true'">
      <xsl:element name="information">
        <xsl:attribute name="type">
          <xsl:value-of select="'sequence'"/>
        </xsl:attribute>
        <xsl:attribute name="name">
          <xsl:value-of select="$name"/>
        </xsl:attribute>
        <xsl:attribute name="schema">
          <xsl:value-of select="$schema"/>
        </xsl:attribute>
        <xsl:element name="comment">
          <xsl:value-of select="$new-comment"/>
        </xsl:element>
      </xsl:element>
    </xsl:if>
  </xsl:template>


  <xsl:template match="table" mode="comment">
    <xsl:variable name="name" select="@name"/>
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="old-comment"
                  select="document($oldfile)//table[@name = $name and @schema = $schema]/comment/text()"/>
    <xsl:variable name="new-comment"
                  select="document($newfile)//table[@name = $name and @schema = $schema]/comment/text()"/>
    <xsl:variable name="old-name"
                  select="document($oldfile)//table[@name = $name and @schema = $schema]/@name"/>
    <xsl:if test="fcn:check-comment($new-comment,$old-comment,$old-name) = 'true'">
      <xsl:element name="information">
        <xsl:attribute name="type">
          <xsl:value-of select="'table'"/>
        </xsl:attribute>
        <xsl:attribute name="name">
          <xsl:value-of select="$name"/>
        </xsl:attribute>
        <xsl:attribute name="schema">
          <xsl:value-of select="$schema"/>
        </xsl:attribute>
        <xsl:element name="comment">
          <xsl:value-of select="$new-comment"/>
        </xsl:element>
      </xsl:element>
    </xsl:if>
    <xsl:apply-templates select="columns/column" mode="comment">
      <xsl:with-param name="schema" select="$schema"/>
      <xsl:with-param name="table"  select="$name"/>
    </xsl:apply-templates>
  </xsl:template>


  <xsl:template match="column" mode="comment">
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:variable name="name" select="@name"/>
    <xsl:variable name="old-comment"
                  select="document($oldfile)//table[@name = $table
                          and @schema = $schema]//column[@name = $name]/comment/text()"/>
    <xsl:variable name="new-comment"
                  select="document($newfile)//table[@name = $table
                          and @schema = $schema]//column[@name = $name]/comment/text()"/>
    <xsl:variable name="old-name"
                  select="document($oldfile)//table[@name = $table
                          and @schema = $schema]//column[@name = $name]/@name"/>
    <xsl:if test="fcn:check-comment($new-comment,$old-comment,$old-name) = 'true'">
      <xsl:element name="information">
        <xsl:attribute name="type">
          <xsl:value-of select="'column'"/>
        </xsl:attribute>
        <xsl:attribute name="name">
          <xsl:value-of select="$name"/>
        </xsl:attribute>
        <xsl:attribute name="schema">
          <xsl:value-of select="$schema"/>
        </xsl:attribute>
        <xsl:attribute name="table">
          <xsl:value-of select="$table"/>
        </xsl:attribute>
        <xsl:element name="comment">
          <xsl:value-of select="$new-comment"/>
        </xsl:element>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  
</xsl:stylesheet>
