<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                extension-element-prefixes="fcn">

  <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>


  <xsl:param name="oldfile"/>

  <xsl:param name="newfile"/>

  <xsl:param name="configfile"/>

  <xsl:param name="filetype"/>

  <xsl:variable name="config" select="document($configfile)/config"/>

  <xsl:variable name="base-schema" select="exslt:node-set($config)/schemaconf[@name = 'base']/@value"/>
  <xsl:variable name="dim-schema"  select="exslt:node-set($config)/schemaconf[@name = 'dim']/@value"/>
  <xsl:variable name="fact-schema" select="exslt:node-set($config)/schemaconf[@name = 'fact']/@value"/>
  <xsl:variable name="hist-schema" select="exslt:node-set($config)/schemaconf[@name = 'hist']/@value"/>

  <xsl:variable name="valid-from"  select="exslt:node-set($config)/columnconf[@name = 'valid-from']/@value"/>
  <xsl:variable name="valid-to"    select="exslt:node-set($config)/columnconf[@name = 'valid-to']/@value"/>


  
  <xsl:variable name="space">
    <xsl:text>                    </xsl:text>
  </xsl:variable>

  <xsl:variable name="tab">
    <xsl:text>    </xsl:text>
  </xsl:variable>

  <xsl:variable name="bigtab">
    <xsl:text>                </xsl:text>
  </xsl:variable>

  
  <xsl:variable name="space-size" select="string-length($space)" />


  <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>

  <xsl:param name="auto"/>
  
  <xsl:include href="functions.xslt"/>

  
  <fcn:function name="fcn:format-column" >
    <xsl:param name="name" />
    <xsl:param name="type" />
    <xsl:variable name="name-size" select="string-length($name)" />     
    <fcn:result>
      <xsl:value-of select="concat($name,substring($space,1,$space-size - $name-size),$type)" />
    </fcn:result>
  </fcn:function>


  <xsl:template name="drop-one-schema">
    <xsl:param name="schema" />
    <xsl:value-of select="concat('drop schema if exists ',$schema,' cascade;',$nl)"/>
  </xsl:template>
  

  <xsl:template name="drop-schemas">
    <xsl:call-template name="drop-one-schema">
      <xsl:with-param name="schema" select="$hist-schema"/>
    </xsl:call-template>
    <xsl:call-template name="drop-one-schema">
      <xsl:with-param name="schema" select="$fact-schema"/>
    </xsl:call-template>
    <xsl:call-template name="drop-one-schema">
      <xsl:with-param name="schema" select="$dim-schema"/>
    </xsl:call-template>
    <xsl:call-template name="drop-one-schema">
      <xsl:with-param name="schema" select="$base-schema"/>
    </xsl:call-template>
    <xsl:value-of select="$nl"/>
  </xsl:template>

  
  <xsl:template name="get-dom-type">
    <xsl:param name="simple-type"/>
    <xsl:choose>
      <xsl:when test="$filetype = 'model'">
        <xsl:value-of select="//domain[@name = $simple-type and @schema = $base-schema]/@type"/>
      </xsl:when>
      <xsl:when test="$filetype = 'delta'">
        <xsl:value-of select="document($newfile)//domain[@name = $simple-type and @schema = $base-schema]/@type"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">
          <xsl:value-of select="concat('undefined file type ',$filetype,$nl)"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template match="model">
    <xsl:call-template name="drop-schemas"/>
    <xsl:value-of select="$nl"/>
    <xsl:apply-templates select="tablespaces/tablespace"/>
    <xsl:value-of select="$nl"/>
    <xsl:apply-templates select="schemas/schema"/>
    <xsl:value-of select="$nl"/>
    <xsl:apply-templates select="domains/domain"/>
    <xsl:value-of select="$nl"/>
    <xsl:apply-templates select="sequences/sequence"/>
    <xsl:value-of select="$nl"/>
    <xsl:apply-templates select="tables/table"/>
    <xsl:value-of select="$nl"/>
    <xsl:apply-templates select="references/reference"/>
    <xsl:value-of select="$nl"/>
    <xsl:apply-templates select="metadata"/>
  </xsl:template>

  
  <xsl:template match="delta">
    <xsl:apply-templates select="tablespaces/tablespace"/>
    <xsl:value-of select="$nl"/>
    <xsl:apply-templates select="schemas/schema"/>
    <xsl:value-of select="$nl"/>
    <xsl:apply-templates select="domains/domain"/>
    <xsl:value-of select="$nl"/>
    <xsl:apply-templates select="sequences/sequence"/>
    <xsl:value-of select="$nl"/>
    <xsl:apply-templates select="tables/table"/>
    <xsl:value-of select="$nl"/>
    <xsl:apply-templates select="references/reference"/>
    <xsl:value-of select="$nl"/>
    <xsl:apply-templates select="informations/information"/>
    <xsl:value-of select="$nl"/>
    <xsl:apply-templates select="metadata"/>
  </xsl:template>

  
  <xsl:template match="tablespace">
    <xsl:variable name="tablespace" select="@name"/>
    <xsl:variable name="location" select="location" />
    <xsl:value-of select="concat('drop tablespace if exists ',$tablespace,';',$nl)"/>
    <xsl:value-of select="concat('create tablespace ',$tablespace,' location ',$q,$location,$q,';',$nl)"/>
    <xsl:if test="comment != ''"> 
      <xsl:value-of select="concat('comment on tablespace ',$tablespace,' is ',$q,comment,$q,';',$nl)"/>
    </xsl:if>
    <xsl:value-of select="$nl"/>
  </xsl:template>


  <xsl:template match="schema">
    <xsl:variable name="schema" select="@name" />
    <xsl:value-of select="concat('create schema ',$schema,';',$nl)"/>
    <xsl:if test="comment != ''"> 
      <xsl:value-of select="concat('comment on schema ',$schema,' is ',$q,comment,$q,';',$nl)"/>
    </xsl:if>
    <xsl:value-of select="$nl"/>
  </xsl:template>

  
  <xsl:template match="domain">
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="string-length(size/text()) != 0">
          <xsl:value-of select="concat(@type,'(',size/text(),')')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@type"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="concat('create domain ',$schema,'.',@name,' as ',$type)"/>
    <xsl:if test="string-length(default) != 0">
      <xsl:value-of select="concat(' default ',default)"/>
    </xsl:if>
    <xsl:if test="string-length(check) != 0">
      <xsl:value-of select="concat(' check ',check)"/>
    </xsl:if>
    <xsl:if test="@nullable = 'NO'">
      <xsl:value-of select="' not null'"/>
    </xsl:if>
    <xsl:if test="constraint/@type = 'any'">
      <xsl:variable name="name" select="constraint/@name"/>
      <xsl:variable name="value-list">
        <xsl:for-each select="constraint/value">
          <xsl:choose>
          <xsl:when test="position() = last()">
            <xsl:value-of select="text()"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat(text(),', ')"/>
          </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="concat($nl,$tab,'constraint ',$name,' check (value in (',$value-list,'))')"/>
    </xsl:if>
    <xsl:value-of select="concat(';',$nl)"/>
    <xsl:if test="string-length(comment)">
      <xsl:value-of select="concat('comment on domain ',$schema,'.',@name,' is ',$q,comment,$q,';',$nl)"/>
    </xsl:if>
    <xsl:value-of select="$nl"/>
  </xsl:template>

  
  <xsl:template match="constraint" mode="check">
    <xsl:param name="schema" />
    <xsl:variable name="constraint" select="@name"/>
    <xsl:variable name="field" select="@field"/>
    <xsl:variable name="value-list">
      <xsl:for-each select="value">
        <xsl:choose>
          <xsl:when test="position() = last()">
            <xsl:value-of select="text()"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat(text(),', ')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each >
    </xsl:variable>
    <xsl:value-of select="concat($tab,fcn:format-column('constraint',$constraint),$nl)" />
    <xsl:value-of select="concat($tab,$space,'check (',$field,' in (',$value-list,')),',$nl)"/>
  </xsl:template>

    
  <xsl:template match="sequence">
    <xsl:variable name="schema" select="@schema"/>
    <xsl:value-of select="concat('create sequence ',$schema,'.',@name,' as ',@type,$nl)"/>
    <xsl:apply-templates select="config"/>
    <xsl:value-of select="concat(';',$nl)"/>
    <xsl:if test="comment != ''">
      <xsl:value-of select="concat('comment on sequence ',$schema,'.',@name,' is ',$q,comment,$q,';',$nl)"/>
    </xsl:if>
    <xsl:value-of select="$nl"/>
  </xsl:template>


  <xsl:template match="table">
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="table" select="@name" />
    <xsl:choose>
      <xsl:when test="@action = 'create'">
        <xsl:apply-templates select="." mode="create"/>
      </xsl:when>
      <xsl:when test="@action = 'alter'">
        <xsl:apply-templates select="." mode="alter"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">
          <xsl:value-of select="concat('Invalid action ',@action,' for table ',@schema,'.',@name,$nl)"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="table" mode="create">
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="table" select="@name" />
    <xsl:variable name="tablespace" select="@tablespace" />
    <xsl:variable name="comment" select="comment" />
    <xsl:value-of select="concat('create table ',$schema,'.',$table,' (',$nl)" />
    <xsl:apply-templates select="columns/column" mode="create">
      <xsl:with-param name="schema" select="$schema" />
    </xsl:apply-templates>
    <xsl:apply-templates select="constraint[@type = 'any']" mode="check">
      <xsl:with-param name="schema" select="$schema" />
    </xsl:apply-templates>
    <xsl:apply-templates select="unique" mode="create">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="table" select="$table" />
      <xsl:with-param name="tablespace" select="$tablespace" />
    </xsl:apply-templates>
    <xsl:apply-templates select="primary" mode="create">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="table" select="$table" />
      <xsl:with-param name="tablespace" select="$tablespace" />
    </xsl:apply-templates>
    <xsl:value-of select="concat(') tablespace ',$tablespace,';',$nl)" />
    <xsl:if test="string-length(comment)">
      <xsl:value-of select="concat('comment on table ',$schema,'.',@name,' is ',$q,comment,$q,';',$nl)"/>
    </xsl:if>
    <xsl:value-of select="$nl" />
    <xsl:apply-templates select="columns/column" mode="comment">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="table" select="$table" />
    </xsl:apply-templates>
    <xsl:value-of select="$nl" />
    <xsl:apply-templates select="/model/functions/function[@schema = $schema and @table = $table]"/>
    <xsl:value-of select="$nl" />
    <xsl:apply-templates select="triggers">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="table" select="$table" />
    </xsl:apply-templates>
    <xsl:value-of select="concat($nl,$nl)" />
  </xsl:template>

  
  <xsl:template match="table" mode="alter">
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="table" select="@name" />
    <xsl:variable name="tablespace" select="@tablespace" />
    <xsl:variable name="comment" select="comment" />
    <xsl:value-of select="concat('alter table ',$schema,'.',$table,$nl)" />
    <xsl:apply-templates select="columns/column" mode="alter">
      <xsl:with-param name="schema" select="$schema" />
    </xsl:apply-templates>
    <xsl:apply-templates select="constraint[@type = 'any']" mode="check">
      <xsl:with-param name="schema" select="$schema" />
    </xsl:apply-templates>
    <xsl:value-of select="concat(';',$nl,$nl)" />

    <xsl:variable name="old-unique"
                  select="document($oldfile)//table[@name = $table and @schema = $schema]/unique/text()"/>
    <xsl:variable name="old-primary"
                  select="document($oldfile)//table[@name = $table and @schema = $schema]/primary/text()"/>
    <xsl:apply-templates select="unique" mode="alter">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="table" select="$table" />
      <xsl:with-param name="tablespace" select="$tablespace" />
      <xsl:with-param name="old-unique" select="$old-unique" />
    </xsl:apply-templates>
    <xsl:apply-templates select="primary" mode="alter">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="table" select="$table" />
      <xsl:with-param name="tablespace" select="$tablespace" />
      <xsl:with-param name="old-primary" select="$old-primary" />
    </xsl:apply-templates>
    <xsl:if test="string-length(comment)">
      <xsl:value-of select="concat('comment on table ',$schema,'.',@name,' is ',$q,comment,$q,';',$nl)"/>
    </xsl:if>
    <xsl:value-of select="$nl" />
    <xsl:apply-templates select="columns/column" mode="comment">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="table" select="$table" />
    </xsl:apply-templates>
    <xsl:value-of select="$nl" />
    <xsl:apply-templates select="document($newfile)//function[@schema = $schema and @table = $table]"/>
    <xsl:value-of select="$nl" />
    <xsl:apply-templates select="triggers">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="table" select="$table" />
    </xsl:apply-templates>
    <xsl:value-of select="concat($nl,$nl)" />
  </xsl:template>

  
  <xsl:template match="references">
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:apply-templates select="reference">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="table" select="$table" />
    </xsl:apply-templates>
  </xsl:template>
  
  
  <xsl:template match="config">
    <xsl:variable name="increment"  select="concat('increment by ',@increment)"/>
    <xsl:variable name="minvalue"   select="concat('   minvalue ',@min)"/>
    <xsl:variable name="maxvalue"   select="concat('   maxvalue ',@max)"/>
    <xsl:variable name="start-with" select="concat('   start with ',@start)"/>
    <xsl:variable name="cycle"      select="fcn:if-then-else(@cycle,' = ','t','   cycle','   no cycle')"/>
    <xsl:value-of select="concat($bigtab,$increment,$minvalue,$maxvalue,$start-with,$cycle)"/>
  </xsl:template>

  
  <xsl:template match="column"  mode="create">
    <xsl:param name="schema" />
    <xsl:param name="table-action" />
    <xsl:variable name="column" select="@name"/>
    <xsl:variable name="simple-type" select="@type"/>
    <xsl:variable name="dom-type">
      <xsl:call-template name="get-dom-type">
        <xsl:with-param name="simple-type" select="$simple-type"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="comment" select="@comment"/>
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="string-length($dom-type) = 0">
          <xsl:choose>
            <xsl:when test="string-length(size/text()) != 0">
              <xsl:value-of select="concat(@type,'(',size/text(),')')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$simple-type"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($base-schema,'.',$simple-type)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="concat($tab,fcn:format-column($column,$type))"/>
    <xsl:if test="string-length(default) != 0">
      <xsl:value-of select="concat(' default ',default)"/>
    </xsl:if>
    <xsl:if test="string-length(check) != 0">
      <xsl:value-of select="concat(' check ',check)"/>
    </xsl:if>
    <xsl:if test="@nullable = 'NO'">
      <xsl:value-of select="' not null'"/>
    </xsl:if>
    <xsl:value-of select="concat(',',$nl)"/>
  </xsl:template>

  
  <xsl:template match="column"  mode="alter">
    <xsl:param name="schema" />
    <xsl:param name="table-action" />
    <xsl:variable name="column" select="@name"/>
    <xsl:variable name="simple-type" select="@type"/>
    <xsl:variable name="dom-type">
      <xsl:call-template name="get-dom-type">
        <xsl:with-param name="simple-type" select="$simple-type"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="comment" select="@comment"/>
    <xsl:variable name="type">
      <xsl:choose>
        <xsl:when test="string-length($dom-type) = 0">
          <xsl:choose>
            <xsl:when test="string-length(size/text()) != 0">
              <xsl:value-of select="concat(@type,'(',size/text(),')')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$simple-type"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($base-schema,'.',$simple-type)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="@action = 'alter'">
        <xsl:value-of select="'      alter '"/>
      </xsl:when>
      <xsl:when test="@action = 'create'">
        <xsl:value-of select="'      add '"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">
          <xsl:value-of select="concat('undefined column action ',@action,$nl)"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
    
    <xsl:value-of select="concat('',fcn:format-column($column,$type))"/>
    <xsl:if test="string-length(default) != 0">
      <xsl:value-of select="concat(' default ',default)"/>
    </xsl:if>
    <xsl:if test="string-length(check) != 0">
      <xsl:value-of select="concat(' check ',check)"/>
    </xsl:if>
    <xsl:if test="@nullable = 'NO'">
      <xsl:value-of select="' not null'"/>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="$table-action = 'create' or position() != last()">
        <xsl:value-of select="concat(',',$nl)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('',$nl)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  
  <xsl:template match="column"  mode="comment">
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:if test="string-length(comment)">
      <xsl:value-of select="concat('comment on column ',$schema,'.',$table,'.',@name,' is ',$q,comment,$q,';',$nl)"/>
    </xsl:if>
  </xsl:template>

  
  <xsl:template match="unique" mode="create">
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:param name="tablespace" />
    <xsl:variable name="constraint" select="@name" />
    <xsl:variable name="key">
       <xsl:for-each select="key">
        <xsl:choose>
        <xsl:when test="position() = last()">
          <xsl:value-of select="text()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat(text(),', ')"/>
        </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each >
    </xsl:variable>
    <xsl:value-of select="concat($tab,fcn:format-column('constraint',$constraint),$nl)" />
    <xsl:value-of select="concat($tab,$space,'unique ',' (',$key,')',$nl)" />
    <xsl:value-of select="concat($tab,$space,'using index tablespace ',$tablespace,',',$nl)" />
  </xsl:template>


  <xsl:template match="unique" mode="alter">
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:param name="tablespace" />
    <xsl:param name="old-unique" />
    <xsl:variable name="constraint" select="@name" />
    <xsl:variable name="key">
       <xsl:for-each select="key">
        <xsl:choose>
        <xsl:when test="position() = last()">
          <xsl:value-of select="text()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat(text(),', ')"/>
        </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each >
    </xsl:variable>
    <xsl:if test="string-length($old-unique) != 0">
      <xsl:value-of select="concat('alter table ',$schema,'.',$table,$nl)" />
      <xsl:value-of select="concat($tab,'drop constraint ',$constraint,';',$nl,$nl)" />
    </xsl:if>
    <xsl:value-of select="concat('alter table ',$schema,'.',$table,$nl)" />
    <xsl:value-of select="concat($tab,'add constraint ',$constraint,$nl)" />
    <xsl:value-of select="concat($tab,'unique ',' (',$key,')',$nl)" />
    <xsl:value-of select="concat($tab,'using index tablespace ',$tablespace,';',$nl,$nl)" />
  </xsl:template>


  <xsl:template match="primary" mode="create">
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:param name="tablespace" />
    <xsl:variable name="constraint" select="@name" />
    <xsl:variable name="key">
       <xsl:for-each select="key">
        <xsl:choose>
        <xsl:when test="position() = last()">
          <xsl:value-of select="text()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat(text(),', ')"/>
        </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each >
    </xsl:variable>
    <xsl:value-of select="concat($tab,fcn:format-column('constraint',$constraint),$nl)" />
    <xsl:value-of select="concat($tab,$space,'primary key ',' (',$key,')',$nl)" />
    <xsl:value-of select="concat($tab,$space,'using index tablespace ',$tablespace,$nl)" />
  </xsl:template>

  
  <xsl:template match="primary" mode="alter">
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:param name="tablespace" />
    <xsl:param name="old-primary" />
    <xsl:variable name="constraint" select="@name" />
    <xsl:variable name="key">
       <xsl:for-each select="key">
        <xsl:choose>
        <xsl:when test="position() = last()">
          <xsl:value-of select="text()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat(text(),', ')"/>
        </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each >
    </xsl:variable>
    <xsl:if test="string-length($old-primary) != 0">
      <xsl:value-of select="concat('alter table ',$schema,'.',$table,$nl)" />
      <xsl:value-of select="concat($tab,'drop constraint ',$constraint,';',$nl,$nl)" />
    </xsl:if>
    <xsl:value-of select="concat('alter table ',$schema,'.',$table,$nl)" />
    <xsl:value-of select="concat($tab,'add constraint ',$constraint,$nl)" />
    <xsl:value-of select="concat($tab,'primary key ',' (',$key,')',$nl)" />
    <xsl:value-of select="concat($tab,'using index tablespace ',$tablespace,';',$nl,$nl)" />
  </xsl:template>

  
  <xsl:template match="triggers">
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:apply-templates select="trigger">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="table" select="$table" />
    </xsl:apply-templates>
  </xsl:template>

  
  <xsl:template match="trigger">
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:variable name="trigger" select="@name"/>
    <xsl:apply-templates select="definition">
      <xsl:with-param name="schema" select="$schema" />
      <xsl:with-param name="table" select="$table" />
      <xsl:with-param name="trigger" select="$trigger" />
    </xsl:apply-templates>
  </xsl:template>

  
  <xsl:template match="definition">
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:param name="trigger" />
    <xsl:variable name="function"    select="call/@name"/>
    <xsl:variable name="constraint"  select="concat('pk_',$table)"/> 
    <xsl:variable name="pk-column"   select="fields/field[@type = 'primary']/@name"/>
    <xsl:variable name="valid-from"  select="fields/field[@type = 'valid-from']/@name"/>
    <xsl:variable name="valid-to"    select="fields/field[@type = 'valid-to']/@name"/>
    <xsl:variable name="statement"   select="concat('EXECUTE FUNCTION ',$dim-schema,'.',$function,'()')"/>
    <xsl:variable name="column-list">
      <xsl:apply-templates select="fields/field[@type = 'other']"/>
    </xsl:variable>
    
    <xsl:if test="$schema != call/@schema">
      <xsl:message terminate="yes">
        <xsl:value-of select="concat('schema missmatch in trigger definition:',$schema,' != ',call/@name,$nl)"/>
      </xsl:message>
    </xsl:if>

    <xsl:value-of select="concat('create or replace trigger ',$trigger,$nl)"/>
    <xsl:value-of select="concat('       ',@timing,' ',@action,' on ',$dim-schema,'.',$table,$nl)"/>
    <xsl:value-of select="concat('       for each ',@level,$nl)"/>
    <xsl:value-of select="concat('       ',$statement,';',$nl,$nl)"/>
  </xsl:template>

  
  <xsl:template match="field">
    <xsl:variable name="field-name" select="@name"/>
    <xsl:variable name="delim" select="fcn:if-then-else(position(),'=',last(),'',',')"/>
    <xsl:value-of select="concat($field-name,$delim)"/>
  </xsl:template>
  
  
  <xsl:template match="function">
    <xsl:value-of select="concat('create or replace function ',@schema,'.',@name,'()',$nl)"/>
    <xsl:value-of select="concat(' returns trigger',$nl)"/>
    <xsl:value-of select="concat(' language ',text/@language,$nl)"/>
    <xsl:value-of select="concat('as $function$',$nl)"/>
    <xsl:value-of select="concat('','  begin')"/>
    <xsl:value-of select="concat('',text/text())"/>
    <xsl:value-of select="concat('  return new;',$nl)"/>
    <xsl:value-of select="concat('  end;',$nl)"/>
    <xsl:value-of select="concat('$function$;',$nl)"/>
    <xsl:value-of select="$nl"/>
  </xsl:template>
  
  
  <xsl:template match="reference">
    <xsl:variable name="name" select="@name" />
    <xsl:variable name="src-schema" select="source/@schema" />
    <xsl:variable name="src-table" select="source/@table" />
    <xsl:variable name="tgt-schema" select="target/@schema" />
    <xsl:variable name="tgt-table" select="target/@table" />
    <xsl:variable name="key" select="foreign/key/text()" />
    <xsl:choose>
      <xsl:when test="@action = 'alter'">
        <xsl:value-of select="concat('alter table ',$src-schema,'.',$src-table,$nl)" />
        <xsl:value-of select="concat('      drop constraint ',$name,';',$nl,$nl)" />
      </xsl:when>
      <xsl:when test="@action = 'create'">
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">
          <xsl:value-of select="concat('undefined action ',@action,' for reference ',$name,$nl)"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="concat('alter table ',$src-schema,'.',$src-table,$nl)" />
    <xsl:value-of select="concat('      add constraint ',$name,$nl)" />
    <xsl:value-of select="concat('      foreign key (',$key,')',$nl)" />
    <xsl:value-of select="concat('      references ',$tgt-schema,'.',$tgt-table,' (',$key,');',$nl,$nl)" />
  </xsl:template>
  
  
  <xsl:template match="information">
    <xsl:choose>
      <xsl:when test="@type = 'tablespace'">
        <xsl:variable name="name" select="@name"/>
        <xsl:value-of select="concat('comment on tablespace ',$name,' is ',$q,comment/text(),$q,';',$nl)" />
      </xsl:when>
      <xsl:when test="@type = 'schema'">
        <xsl:variable name="name" select="@name"/>
        <xsl:value-of select="concat('comment on schema ',$name,' is ',$q,comment/text(),$q,';',$nl)" />
      </xsl:when>
      <xsl:when test="@type = 'domain'">
        <xsl:variable name="name" select="concat(@schema,'.',@name)"/>
        <xsl:value-of select="concat('comment on domain ',$name,' is ',$q,comment/text(),$q,';',$nl)" />
      </xsl:when>
      <xsl:when test="@type = 'sequence'">
        <xsl:variable name="name" select="concat(@schema,'.',@name)"/>
        <xsl:value-of select="concat('comment on sequence ',$name,' is ',$q,comment/text(),$q,';',$nl)" />
      </xsl:when>
      <xsl:when test="@type = 'table'">
        <xsl:variable name="name" select="concat(@schema,'.',@name)"/>
        <xsl:value-of select="concat('comment on table ',$name,' is ',$q,comment/text(),$q,';',$nl)" />
      </xsl:when>
      <xsl:when test="@type = 'column'">
        <xsl:variable name="name" select="concat(@schema,'.',@table,'.',@name)"/>
        <xsl:value-of select="concat('comment on column ',$name,' is ',$q,comment/text(),$q,';',$nl)" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">
          <xsl:value-of select="concat('undefined information type',@type,$nl)"/>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
  <xsl:template match="metadata">
    <xsl:apply-templates select="table"/>
    <xsl:apply-templates select="insert"/>
    <xsl:apply-templates select="update"/>
    <xsl:apply-templates select="commit"/>
  </xsl:template>

  
  <xsl:template match="insert">
    <xsl:value-of select="concat('insert into ',@schema,'.',@table,' (project, version)',$nl)"/>
    <xsl:value-of select="concat('            values (',$q,project/text(),$q,', ',version/text(),');',$nl,$nl)"/>
  </xsl:template>


  <xsl:template match="update">
    <xsl:value-of select="concat('update ',@schema,'.',@table,$nl)"/>
    <xsl:value-of select="concat('   set version = ',version/text(),';',$nl,$nl)"/>

  </xsl:template>


  <xsl:template match="commit">
    <xsl:value-of select="concat('commit;',$nl,$nl)"/>
  </xsl:template>


</xsl:stylesheet> 
