<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dia="http://www.lysator.liu.se/~alla/dia/"
                extension-element-prefixes="fcn exslt">

  <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

  <xsl:param name="projectfile"/>
  
  <xsl:variable name="nl" select="'&#10;'" />

  <xsl:include href="functions.xslt"/>

  
  <fcn:function name="fcn:strip" >
    <xsl:param name="arg" />
    <fcn:result>
      <xsl:value-of select="substring($arg,2,string-length($arg) - 2)" />
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:encode-boolean" >
    <xsl:param name="string" />

    <fcn:result>
      <xsl:choose>
        <xsl:when test="$string = 'true'">
          <xsl:value-of select="'YES'" />
        </xsl:when>
        <xsl:when test="$string = 'false'">
          <xsl:value-of select="'NO'" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="''" />
        </xsl:otherwise>
      </xsl:choose>
    </fcn:result>
  </fcn:function>


  <fcn:function name="fcn:get-table-name">
    <xsl:param name="id" />
    <xsl:variable name="name">
      <xsl:value-of select="//dia:object[@id = $id]/dia:attribute[@name = 'name']/dia:string/text()"/>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="fcn:strip($name)" />
    </fcn:result>
  </fcn:function>
  

  <xsl:template match="dia:diagram">
    <xsl:variable name="name" select="dia:layer[@active='true']/@name" />
    <xsl:value-of select="concat('diagram#',$name,$nl)"/>
    <xsl:apply-templates select="dia:layer[@active='true']" />
  </xsl:template>

  
  <xsl:template match="dia:layer">
    <xsl:apply-templates select="dia:object[@type = 'Database - Table']" mode="proc-metadata">
      <xsl:with-param name="proc-table-name" select="'MetaData'"/>
    </xsl:apply-templates>
    <xsl:apply-templates select="dia:object[@type = 'Database - Table']" mode="proc-domain">
      <xsl:with-param name="proc-table-name" select="'Domains'"/>
    </xsl:apply-templates>
    <xsl:value-of select="concat('sequences',$nl)" />
    <xsl:variable name="sequence-var">
      <xsl:apply-templates select="dia:object[@type = 'Database - Table']" mode="proc-sequence">
        <xsl:with-param name="skip-table-name-list" select="'Domains,MetaData'"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:for-each select="exslt:node-set($sequence-var)/sequence-list/*">
      <xsl:sort select="node()"/>
      <xsl:value-of select="concat('sequence#',@table,'#',@column,$nl)"/>
    </xsl:for-each>
    <xsl:value-of select="concat('end',$nl)" />    
    <xsl:value-of select="concat('tables',$nl)" />
    <xsl:apply-templates select="dia:object[@type = 'Database - Table']" mode="proc-table">
      <xsl:with-param name="skip-table-name-list" select="'Domains,MetaData'"/>
    </xsl:apply-templates>
    <xsl:value-of select="concat('end',$nl)" />    
    <xsl:value-of select="concat('references',$nl)" />
    <xsl:apply-templates select="dia:object[@type = 'Database - Reference']" mode="reference" />
    <xsl:value-of select="concat('end',$nl)" />
  </xsl:template>


  <xsl:template match="dia:object" mode="proc-metadata">
    <xsl:param name="proc-table-name"/> 
    <xsl:variable name="table-name" select="fcn:strip(dia:attribute[@name = 'name']/dia:string/text())"/>
    <xsl:if test="$table-name = $proc-table-name">
      <xsl:value-of select="concat('metadata',$nl)" />
      <xsl:apply-templates select="dia:attribute[@name='attributes']/dia:composite" mode="metadata" />
      <xsl:value-of select="concat('end',$nl)" />
    </xsl:if>
  </xsl:template>

  
  <xsl:template match="dia:object" mode="proc-domain">
    <xsl:param name="proc-table-name"/> 
    <xsl:variable name="table-name" select="fcn:strip(dia:attribute[@name = 'name']/dia:string/text())"/>
    <xsl:if test="$table-name = $proc-table-name">
      <xsl:value-of select="concat('domains',$nl)" />
      <xsl:for-each select="dia:attribute[@name='attributes']/dia:composite">
        <xsl:sort select="dia:attribute/dia:string"/>
        <xsl:call-template name="domain"/> 
      </xsl:for-each>
      <xsl:value-of select="concat('end',$nl)" />
    </xsl:if>
  </xsl:template>

  
  <xsl:template match="dia:object" mode="proc-table">
    <xsl:param name="skip-table-name-list"/> 
    <xsl:variable name="table-name" select="fcn:strip(dia:attribute[@name = 'name']/dia:string/text())"/>
    <xsl:if test="not(contains($skip-table-name-list,$table-name))">
      <xsl:variable name="comment" select="fcn:strip(dia:attribute[@name='comment']/dia:string/text())" />
      <xsl:value-of select="concat('table#',@id,'#',$table-name,'#',$comment,$nl)" />
      <xsl:apply-templates select="dia:attribute[@name='attributes']/dia:composite" mode="column" />

      <xsl:variable name="unique">
        <xsl:apply-templates select="dia:attribute[@name='attributes']/dia:composite" mode="unique" />
      </xsl:variable>
      <xsl:variable name="pk">
        <xsl:apply-templates select="dia:attribute[@name='attributes']/dia:composite" mode="primary-key" />
      </xsl:variable>
      <xsl:if test="$unique != ''">
        <xsl:value-of select="concat('unique#',substring-after($unique,','),$nl)" />
      </xsl:if>
      <xsl:value-of select="concat('primary#',substring-after($pk,','),$nl)" />
      <xsl:value-of select="concat('end',$nl)" />
    </xsl:if>
  </xsl:template>


  <xsl:template match="dia:object" mode="proc-sequence">
    <xsl:param name="skip-table-name-list"/> 
    <xsl:variable name="table-name" select="fcn:strip(dia:attribute[@name = 'name']/dia:string/text())"/>
    <xsl:element name="sequence-list">
      <xsl:if test="not(contains($skip-table-name-list,$table-name))">
        <xsl:apply-templates select="dia:attribute[@name='attributes']/dia:composite" mode="sequence" >
          <xsl:with-param name="table" select="$table-name"/>
        </xsl:apply-templates>
      </xsl:if>
    </xsl:element>
  </xsl:template>


  <xsl:template name="domain" >
    <xsl:variable name="name" select="fcn:strip(dia:attribute[@name='name']/dia:string/text())" />
    <xsl:variable name="type" select="fcn:strip(dia:attribute[@name='type']/dia:string/text())" />
    <xsl:variable name="comment" select="fcn:strip(dia:attribute[@name='comment']/dia:string/text())" />
    <xsl:variable name="default" select="fcn:strip(dia:attribute[@name='default_value']/dia:string/text())" />
    <xsl:variable name="nullable" select="fcn:encode-boolean(dia:attribute[@name='nullable']/dia:boolean/@val)" />
    <xsl:value-of select="concat('domain#',$name,'#',$type,'#',$default,'#',$nullable,'#',$comment,$nl)" />
  </xsl:template>
  
  
  <xsl:template match="dia:composite" mode="metadata" >
    <xsl:variable name="name" select="fcn:strip(dia:attribute[@name='name']/dia:string/text())" />
    <xsl:variable name="lc-name" select="fcn:to-lower-case($name)" />
    <xsl:variable name="type" select="fcn:strip(dia:attribute[@name='type']/dia:string/text())" />
    <xsl:variable name="comment" select="fcn:strip(dia:attribute[@name='comment']/dia:string/text())" />
    <xsl:value-of select="concat($lc-name,'#',$type,'#',$comment,$nl)" />
  </xsl:template>
  
  
  <xsl:template match="dia:composite" mode="sequence" >
    <xsl:param name="table"/>
    <xsl:variable name="name" select="fcn:strip(dia:attribute[@name='name']/dia:string/text())" />
    <xsl:variable name="prefix" select="substring-before($name,'_Id')"/>
    <xsl:variable name="type" select="fcn:strip(dia:attribute[@name='type']/dia:string/text())" />
    <xsl:variable name="pk" select="dia:attribute[@name='primary_key']/dia:boolean/@val" />
    <xsl:if test="$pk = 'true' and $type = 'Id_Type' and $table = $prefix" >
      <xsl:element name="sequence">
        <xsl:attribute name="table">
          <xsl:value-of select="$table" />
        </xsl:attribute>
        <xsl:attribute name="column">
          <xsl:value-of select="$name" />
        </xsl:attribute>
        <xsl:value-of select="concat($table,':',$name)" />
      </xsl:element>
    </xsl:if>       
  </xsl:template>
  
  
  <xsl:template match="dia:composite" mode="column" >
    <xsl:variable name="name" select="fcn:strip(dia:attribute[@name='name']/dia:string/text())" />
    <xsl:variable name="type" select="fcn:strip(dia:attribute[@name='type']/dia:string/text())" />
    <xsl:variable name="comment" select="fcn:strip(dia:attribute[@name='comment']/dia:string/text())" />
    <xsl:variable name="default" select="fcn:strip(dia:attribute[@name='default_value']/dia:string/text())" />
    <xsl:variable name="nullable" select="fcn:encode-boolean(dia:attribute[@name='nullable']/dia:boolean/@val)" />
    <xsl:value-of select="concat('column#',$name,'#',$type,'#',$default,'#',$nullable,'#',$comment,$nl)" />
  </xsl:template>
  
  
  <xsl:template match="dia:composite" mode="primary-key" >
    <xsl:variable name="name" select="fcn:strip(dia:attribute[@name='name']/dia:string/text())" />
    <xsl:variable name="primary" select="dia:attribute[@name='primary_key']/dia:boolean/@val" />
    <xsl:if test="$primary = 'true'" >
      <xsl:value-of select="concat(',',$name)" />
    </xsl:if>       
  </xsl:template>
  
  
  <xsl:template match="dia:composite" mode="unique" >
    <xsl:variable name="name" select="fcn:strip(dia:attribute[@name='name']/dia:string/text())" />
    <xsl:variable name="unique" select="dia:attribute[@name='unique']/dia:boolean/@val" />
    <xsl:if test="$unique = 'true'" >
      <xsl:value-of select="concat(',',$name)" />
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
    <xsl:variable name="from-ref" select="dia:connection[@handle='0']/@to" />
    <xsl:variable name="to-ref" select="dia:connection[@handle='1']/@to" />
    <xsl:variable name="from-name" select="fcn:get-table-name($from-ref)"/>
    <xsl:variable name="to-name" select="fcn:get-table-name($to-ref)"/>

    <xsl:value-of select="concat('foreign#',$from-ref,'#',$from-desc,'#',$to-ref,'#',$to-desc,$nl)" />
    
  </xsl:template>
  

</xsl:stylesheet> 
