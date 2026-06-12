<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dia="http://www.lysator.liu.se/~alla/dia/"
                xmlns:str="http://exslt.org/strings"
                extension-element-prefixes="fcn exslt str">

  <xsl:output method="xml"
              omit-xml-declaration="no"
              indent="yes"
              version="1.0"
              doctype-system="diagram.dtd"
              />

  

  <xsl:include href="functions.xslt"/>

  <xsl:variable name="project">
    <xsl:for-each select="//dia:object/dia:attribute[@name = 'name']/dia:string[text() = '#MetaData#']/text()/../../..">
      <xsl:for-each select="dia:attribute[@name = 'attributes']/dia:composite[@type = 'table_attribute']">
        <xsl:for-each select="dia:attribute[@name = 'name']/dia:string[text() = '#Projekt#']/../..">
          <xsl:variable name="raw-name" select="dia:attribute[@name = 'type']/dia:string/text()"/>
          <xsl:value-of select="fcn:to-lower-case(fcn:strip($raw-name))"/>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:variable>

  <xsl:variable name="version">
    <xsl:for-each select="//dia:object/dia:attribute[@name = 'name']/dia:string[text() = '#MetaData#']/text()/../../..">
      <xsl:for-each select="dia:attribute[@name = 'attributes']/dia:composite[@type = 'table_attribute']">
        <xsl:for-each select="dia:attribute[@name = 'name']/dia:string[text() = '#Version#']/../..">
          <xsl:variable name="raw-name" select="dia:attribute[@name = 'type']/dia:string/text()"/>
          <xsl:value-of select="fcn:to-lower-case(fcn:strip($raw-name))"/>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:variable>

  <xsl:include href="configuration.xslt"/>
  
  
  <xsl:template match="dia:diagram">
    <xsl:call-template name="check-config">
      <xsl:with-param name="name" select="'project,version'"/>
    </xsl:call-template>
    <xsl:variable name="name" select="dia:layer[@active='true']/@name" />
    <xsl:element name="diagram">
      <xsl:attribute name="name">
        <xsl:value-of select="$name"/>
      </xsl:attribute>
      <xsl:apply-templates select="dia:layer[@active='true']" />
    </xsl:element>
  </xsl:template>

  
  <xsl:template match="dia:layer">
    <xsl:apply-templates select="dia:object[@type = 'Database - Table']" mode="proc-metadata">
      <xsl:with-param name="proc-table-name" select="'MetaData'"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="dia:object[@type = 'Database - Table']" mode="proc-domain">
      <xsl:with-param name="proc-table-name" select="'Domains'"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="dia:object[@type = 'Database - Table']" mode="proc-sequence">
      <xsl:with-param name="proc-table-name" select="'MetaData'"/>
    </xsl:apply-templates>
    <xsl:element name="tables">
      <xsl:apply-templates select="dia:object[@type = 'Database - Table']" mode="proc-table">
        <xsl:with-param name="skip-table-name-list" select="'Domains,MetaData'"/>
      </xsl:apply-templates>
    </xsl:element>
    <xsl:element name="references">
      <xsl:apply-templates select="dia:object[@type = 'Database - Reference']" mode="reference" />
    </xsl:element>
  </xsl:template>


  <xsl:template match="dia:object" mode="proc-metadata">
    <xsl:param name="proc-table-name"/> 
    <xsl:variable name="table-name" select="fcn:strip(dia:attribute[@name = 'name']/dia:string/text())"/>
    <xsl:if test="$table-name = $proc-table-name">
      <xsl:element name="metadata">
        <xsl:apply-templates select="dia:attribute[@name='attributes']/dia:composite" mode="metadata" />
      </xsl:element>
    </xsl:if>
  </xsl:template>

  
  <xsl:template match="dia:composite" mode="metadata" >
    <xsl:variable name="name" select="fcn:strip(dia:attribute[@name='name']/dia:string/text())" />
    <xsl:variable name="lc-name" select="fcn:to-lower-case($name)" />
    <xsl:variable name="type" select="fcn:strip(dia:attribute[@name='type']/dia:string/text())" />
    <xsl:variable name="details" select="fcn:strip(dia:attribute[@name='comment']/dia:string/text())" />
    <xsl:element name="metaitem">
      <xsl:attribute name="name">
        <xsl:value-of select="$lc-name" />
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="$type" />
      </xsl:attribute>
      <xsl:for-each select="str:tokenize($details,',')">
        <xsl:element name="metadetail">
          <xsl:attribute name="name">
            <xsl:value-of select="text()"/>
          </xsl:attribute>
        </xsl:element>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>
  
  
  <xsl:template match="dia:object" mode="proc-domain">
    <xsl:param name="proc-table-name"/> 
    <xsl:variable name="table" select="fcn:strip(dia:attribute[@name = 'name']/dia:string/text())"/>
    <xsl:if test="$table = $proc-table-name">
      <xsl:element name="domains">
        <xsl:for-each select="dia:attribute[@name='attributes']/dia:composite">
          <xsl:sort select="dia:attribute/dia:string"/>
          <xsl:call-template name="domain"/> 
        </xsl:for-each>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  
  <xsl:template name="domain" >
    <xsl:variable name="name" select="fcn:strip(dia:attribute[@name='name']/dia:string/text())" />
    <xsl:variable name="type" select="fcn:strip(dia:attribute[@name='type']/dia:string/text())" />
    <xsl:variable name="comment" select="fcn:strip(dia:attribute[@name='comment']/dia:string/text())" />
    <xsl:variable name="default" select="fcn:strip(dia:attribute[@name='default_value']/dia:string/text())" />
    <xsl:variable name="nullable" select="dia:attribute[@name='nullable']/dia:boolean/@val" />
    <xsl:element name="domain">
      <xsl:attribute name="name">
        <xsl:value-of select="$name" />
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="$type" />
      </xsl:attribute>
      <xsl:attribute name="nullable">
        <xsl:value-of select="$nullable" />
      </xsl:attribute>
      <xsl:if test="string-length($default) != 0">
        <xsl:element name="default">
          <xsl:value-of select="$default" />
        </xsl:element>
      </xsl:if>
      <xsl:element name="comment">
        <xsl:value-of select="$comment" />
      </xsl:element>
    </xsl:element>
  </xsl:template>
  
  
  <xsl:template match="dia:object" mode="proc-sequence">
    <xsl:param name="proc-table-name"/> 
    <xsl:variable name="table-name" select="fcn:strip(dia:attribute[@name = 'name']/dia:string/text())"/>
    <xsl:if test="$table-name = $proc-table-name">
      <xsl:element name="sequences">
        <xsl:apply-templates select="dia:attribute[@name='attributes']/dia:composite" mode="sequence" />
      </xsl:element>
    </xsl:if>
  </xsl:template>

  
  <xsl:template match="dia:composite" mode="sequence" >
    <xsl:variable name="schema" select="fcn:strip(dia:attribute[@name='type']/dia:string/text())" />
    <xsl:variable name="table-list" select="fcn:strip(dia:attribute[@name='comment']/dia:string/text())" />
    <xsl:if test="$schema = 'Const' or $schema = 'Dim'" >
      <xsl:for-each select="str:tokenize($table-list,',')">
        <xsl:sort select="concat($schema,text())"/>
        <xsl:variable name="table" select="text()"/>
        <xsl:element name="sequence">
          <xsl:attribute name="schema">
            <xsl:value-of select="$schema" />
          </xsl:attribute>
          <xsl:attribute name="table">
            <xsl:value-of select="$table" />
          </xsl:attribute>
        </xsl:element>
      </xsl:for-each>
    </xsl:if>       
  </xsl:template>
  
  
  <xsl:template match="dia:object" mode="proc-table">
    <xsl:param name="skip-table-name-list"/> 
    <xsl:variable name="name" select="fcn:strip(dia:attribute[@name = 'name']/dia:string/text())"/>
    <xsl:variable name="id" select="@id"/>
    <xsl:if test="not(contains($skip-table-name-list,$name))">
      <xsl:variable name="comment" select="fcn:strip(dia:attribute[@name='comment']/dia:string/text())" />
      <xsl:element name="table">
        <xsl:attribute name="id">
          <xsl:value-of select="$id" />
        </xsl:attribute>
        <xsl:attribute name="name">
          <xsl:value-of select="$name" />
        </xsl:attribute>
        <xsl:element name="columns">
          <xsl:apply-templates select="dia:attribute[@name='attributes']/dia:composite" mode="column" />
        </xsl:element>
        <xsl:variable name="unique">
          <xsl:apply-templates select="dia:attribute[@name='attributes']/dia:composite" mode="unique-string" />
        </xsl:variable>
        <xsl:if test="$unique != ''">
          <xsl:element name="unique">
            <xsl:apply-templates select="dia:attribute[@name='attributes']/dia:composite" mode="unique" />
          </xsl:element>
        </xsl:if>
          <xsl:element name="primary">
            <xsl:apply-templates select="dia:attribute[@name='attributes']/dia:composite" mode="primary-key" />
          </xsl:element>
        <xsl:element name="comment">
          <xsl:value-of select="$comment" />
        </xsl:element>
      </xsl:element>
    </xsl:if>
  </xsl:template>


  <xsl:template match="dia:composite" mode="column" >
    <xsl:variable name="name" select="fcn:strip(dia:attribute[@name='name']/dia:string/text())" />
    <xsl:variable name="type" select="fcn:strip(dia:attribute[@name='type']/dia:string/text())" />
    <xsl:variable name="comment" select="fcn:strip(dia:attribute[@name='comment']/dia:string/text())" />
    <xsl:variable name="default" select="fcn:strip(dia:attribute[@name='default_value']/dia:string/text())" />
    <xsl:variable name="nullable" select="dia:attribute[@name='nullable']/dia:boolean/@val" />
    <xsl:element name="column">
      <xsl:attribute name="name">
        <xsl:value-of select="$name" />
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="$type" />
      </xsl:attribute>
      <xsl:attribute name="nullable">
        <xsl:value-of select="$nullable" />
      </xsl:attribute>
      <xsl:if test="string-length($default) != 0">
        <xsl:element name="default">
          <xsl:value-of select="$default" />
        </xsl:element>
      </xsl:if>
      <xsl:element name="comment">
        <xsl:value-of select="$comment" />
      </xsl:element>
    </xsl:element>
   </xsl:template>
  
  
  <xsl:template match="dia:composite" mode="primary-key" >
    <xsl:variable name="name" select="fcn:strip(dia:attribute[@name='name']/dia:string/text())" />
    <xsl:variable name="primary" select="dia:attribute[@name='primary_key']/dia:boolean/@val" />
    <xsl:if test="$primary = 'true'" >
      <xsl:element name="key">
        <xsl:attribute name="name">
          <xsl:value-of select="$name" />
        </xsl:attribute>
      </xsl:element>
    </xsl:if>       
  </xsl:template>
  
  
  <xsl:template match="dia:composite" mode="unique-string" >
    <xsl:variable name="name" select="fcn:strip(dia:attribute[@name='name']/dia:string/text())" />
    <xsl:variable name="unique" select="dia:attribute[@name='unique']/dia:boolean/@val" />
    <xsl:if test="$unique = 'true'" >
      <xsl:value-of select="$name" />
    </xsl:if>       
  </xsl:template>
  
  
  <xsl:template match="dia:composite" mode="unique" >
    <xsl:variable name="name" select="fcn:strip(dia:attribute[@name='name']/dia:string/text())" />
    <xsl:variable name="unique" select="dia:attribute[@name='unique']/dia:boolean/@val" />
    <xsl:if test="$unique = 'true'" >
      <xsl:element name="key">
        <xsl:attribute name="name">
          <xsl:value-of select="$name" />
        </xsl:attribute>
      </xsl:element>
    </xsl:if>       
  </xsl:template>
  
  
  <xsl:template match="dia:object" mode="reference">
    <xsl:variable name="from-desc" select="fcn:strip(dia:attribute[@name='start_point_desc']/dia:string/text())" />
    <xsl:variable name="to-desc" select="fcn:strip(dia:attribute[@name='end_point_desc']/dia:string/text())" />
    <xsl:apply-templates select="dia:connections">
      <xsl:with-param name="from-desc" select="$from-desc" />
      <xsl:with-param name="to-desc" select="$to-desc" />
    </xsl:apply-templates>
  </xsl:template>
  


  <xsl:template match="dia:connections">
    <xsl:param name="from-desc" />
    <xsl:param name="to-desc" />
    <xsl:variable name="from-id" select="dia:connection[@handle='0']/@to" />
    <xsl:variable name="to-id" select="dia:connection[@handle='1']/@to" />

    <xsl:element name="reference">
      <xsl:element name="from">
        <xsl:attribute name="id">
          <xsl:value-of select="$from-id" />
        </xsl:attribute>
        <xsl:attribute name="mult">
          <xsl:value-of select="$from-desc" />
        </xsl:attribute>
      </xsl:element>
      <xsl:element name="to">
        <xsl:attribute name="id">
          <xsl:value-of select="$to-id" />
        </xsl:attribute>
        <xsl:attribute name="mult">
          <xsl:value-of select="$to-desc" />
        </xsl:attribute>
      </xsl:element>
    </xsl:element>
  </xsl:template>


</xsl:stylesheet> 
