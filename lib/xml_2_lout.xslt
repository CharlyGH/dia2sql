<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                extension-element-prefixes="fcn">

  <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

  <xsl:variable name="tab">
    <xsl:text>    </xsl:text>
  </xsl:variable>

  <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>

  <xsl:variable name="max-size" select="5" />

  <xsl:variable name="dim-schema" select="/model/schemas/schema[position() = 1]/@name"/>
 
  <xsl:include href="functions.xslt"/>

  
  <fcn:function name="fcn:format-sequence-name" >
    <xsl:param name="source" />
    <xsl:param name="schema" />
    <xsl:variable name="prefix" select="substring-before($source,'(')" />
    <xsl:variable name="suffix" select="substring-after($source,'(')" />
    <xsl:variable name="temp1" select="fcn:replace($suffix,concat($q,$schema,'.'),'')" />
    <xsl:variable name="temp2" select="fcn:replace($temp1,concat($q,'::regclass'),'')" />
    <xsl:variable name="target" select="concat($prefix,'(',fcn:format-name($temp2))" />
    <fcn:result>
      <xsl:choose>
        <xsl:when test="$prefix = 'nextval'">
          <xsl:value-of select="$target" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$source" />
        </xsl:otherwise>
      </xsl:choose>
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:tbl-fmt-expand">
    <xsl:param name="prefix"/>
    <xsl:param name="list"/>
    <xsl:variable name="head" select="substring-before($list,',')"/>
    <xsl:variable name="tail" select="substring-after($list,',')"/>
    <fcn:result>
      <xsl:choose>
        <xsl:when test="$tail = ''">
          <xsl:value-of select="concat($prefix,$list,' |')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($prefix,$head,' |',fcn:tbl-fmt-expand($prefix,$tail))"/>
        </xsl:otherwise>
      </xsl:choose>
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:tbl-format">
    <xsl:param name="type"/>
    <xsl:param name="list"/>
    <xsl:if test="$type != 'h' and $type != 'd'">
      <xsl:message terminate="yes">
        <xsl:value-of select="concat('unknown tbl format type:',$type,$nl)"/>
      </xsl:message>
    </xsl:if>
    <xsl:variable name="o-head"   select="concat('    ',$type,'format { | ')"/>
    <xsl:variable name="o-tail"   select="' }'"/>
    <xsl:variable name="prefix" select="fcn:if-then-else($type,'=','h',' @B @Cell ','    @Cell ')"/>
    <fcn:result>
      <xsl:value-of select="concat($o-head,fcn:tbl-fmt-expand($prefix,$list),$o-tail)"/>
    </fcn:result>
  </fcn:function>

   
  <xsl:template match="model">
    <xsl:variable name="fullname" select="concat(fcn:to-capital-case(@project),' (Version ',@version,')')"/>
    <xsl:value-of select="concat('@SysInclude { tbl }',$nl)"/>
    <xsl:value-of select="concat('@Include { diadoc }',$nl)"/>
    <xsl:value-of select="concat('@Doc @Text @Begin',$nl)"/>
    <xsl:value-of select="concat('@Display { 24p @Font{ Datenmodell @I {',$fullname,'}}}',$nl)"/>
    <xsl:value-of select="concat(comment/text(),$nl)"/>

    <xsl:value-of select="concat('@BeginSections',$nl)"/>
    <xsl:value-of select="concat('@Section',$nl)"/>
    <xsl:value-of select="concat('@Title { Übersicht }',$nl)"/>
    <xsl:value-of select="concat('@NewPage { No }',$nl)"/>
    <xsl:value-of select="concat('@Begin',$nl)"/>
    <xsl:value-of select="concat('@BeginSubSections',$nl,$nl)"/>
    
    <xsl:apply-templates select="tablespaces"/>
    <xsl:apply-templates select="schemas" mode="overview"/>

    <xsl:value-of select="concat('@EndSubSections',$nl)"/>
    <xsl:value-of select="concat('@End @Section',$nl,$nl)"/>

    <xsl:value-of select="concat('@Section',$nl)"/>
    <xsl:value-of select="concat('@Title { Details }',$nl)"/>
    <xsl:value-of select="concat('@NewPage { Yes }',$nl)"/>
    <xsl:value-of select="concat('@Begin',$nl)"/>
    <xsl:value-of select="concat('@BeginSubSections',$nl,$nl)"/>
    
    <xsl:apply-templates select="schemas" mode="details"/>

    <xsl:value-of select="concat('@EndSubSections',$nl)"/>
    <xsl:value-of select="concat('@End @Section',$nl,$nl)"/>
    <xsl:value-of select="concat('@EndSections',$nl,$nl)"/>
    
    <xsl:value-of select="concat('@End @Text',$nl,$nl)"/>
  </xsl:template>


  <xsl:template match="tablespaces">
    <xsl:value-of select="concat('@SubSection',$nl)"/>
    <xsl:value-of select="concat('@Title { Tablespaces }',$nl)"/>
    <xsl:value-of select="concat('@NewPage { No }',$nl)"/>
    <xsl:value-of select="concat('@Begin',$nl)"/>
    <xsl:value-of select="concat('@LP',$nl)"/>
    <xsl:value-of select="concat('@Tbl',$nl)"/>
    <xsl:value-of select="concat('rule {yes }',$nl)"/>
    <xsl:value-of select="concat(fcn:tbl-format('h','A,B'),$nl)"/>
    <xsl:value-of select="concat(fcn:tbl-format('d','A,B'),$nl)"/>
    <xsl:value-of select="concat('{',$nl)"/>
    <xsl:value-of select="concat('@Rowh',$nl)"/>
    <xsl:value-of select="concat('    A {Name}',$nl)"/>
    <xsl:value-of select="concat('    B {Verzeichnis}',$nl)"/>
    <xsl:apply-templates select="tablespace"/>
    <xsl:value-of select="concat('}',$nl)"/>
    <xsl:value-of select="concat('@LP',$nl)"/>
    <xsl:value-of select="concat('@End @SubSection',$nl,$nl)"/>
  </xsl:template>


  <xsl:template match="tablespace">
    <xsl:value-of select="concat('@Rowd',$nl)"/>
    <xsl:value-of select="concat('    A {',fcn:format-name(@name),'}',$nl)"/>
    <xsl:value-of select="concat('    B {',$dq,location/text(),$dq,'}',$nl)"/>
  </xsl:template>


  <xsl:template match="schemas" mode="overview">
    <xsl:value-of select="concat('@SubSection',$nl)"/>
    <xsl:value-of select="concat('@Title { Schemas }',$nl)"/>
    <xsl:value-of select="concat('@NewPage { No }',$nl)"/>
    <xsl:value-of select="concat('@Begin',$nl)"/>
    <xsl:value-of select="concat('@LP',$nl)"/>
    <xsl:value-of select="concat('@Tbl',$nl)"/>
    <xsl:value-of select="concat('rule {yes }',$nl)"/>
    <xsl:value-of select="concat(fcn:tbl-format('h','A,B,C'),$nl)"/>
    <xsl:value-of select="concat(fcn:tbl-format('d','A,B,C'),$nl)"/>
    <xsl:value-of select="concat('{',$nl)"/>
    <xsl:value-of select="concat('@Rowh',$nl)"/>
    <xsl:value-of select="concat('    A {Name}',$nl)"/>
    <xsl:value-of select="concat('    B {Kommentar}',$nl)"/>
    <xsl:value-of select="concat('    C {Tablespace}',$nl)"/>
    <xsl:apply-templates select="schema" mode="overview"/>
    <xsl:value-of select="concat('}',$nl)"/>
    <xsl:value-of select="concat('@LP',$nl)"/>
    <xsl:value-of select="concat('@End @SubSection',$nl,$nl)"/>
  </xsl:template>

  
  <xsl:template match="schema" mode="overview">
    <xsl:value-of select="concat('@Rowd',$nl)"/>
    <xsl:value-of select="concat('    A {',fcn:format-name(@name),'}',$nl)"/>
    <xsl:value-of select="concat('    B {',comment/text(),'}',$nl)"/>
    <xsl:value-of select="concat('    C {',fcn:format-name(@name),'}',$nl)"/>
  </xsl:template>

  
  <xsl:template match="schemas" mode="details">
    <xsl:apply-templates select="schema" mode="details"/>
  </xsl:template>

  
  <xsl:template match="schema" mode="details">
    <xsl:variable name="schema" select="@name"/>
    <xsl:variable name="domain-count" select="count(/model/domains/domain[@schema = $schema])"/>
    <xsl:variable name="sequence-count" select="count(/model/sequences/sequence[@schema = $schema])"/>
    <xsl:variable name="table-count" select="count(/model/tables/table[@schema = $schema])"/>
    <xsl:if test="$domain-count">
      <xsl:apply-templates select="/model/domains">
       <xsl:with-param name="schema" select="$schema"/>
      </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="$sequence-count">
        <xsl:apply-templates select="/model/sequences">
        <xsl:with-param name="schema" select="$schema"/>
      </xsl:apply-templates>
    </xsl:if>
    <xsl:if test="$table-count">
      <xsl:apply-templates select="/model/tables">
        <xsl:with-param name="schema" select="$schema"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  
  <xsl:template match="domains">
    <xsl:param name="schema"/>
    <xsl:value-of select="concat('@SubSection',$nl)"/>
    <xsl:value-of select="concat('@Title { Domains im Schema ',fcn:format-name($schema),'}',$nl)"/>
    <xsl:value-of select="concat('@NewPage { No }',$nl)"/>
    <xsl:value-of select="concat('@Begin',$nl)"/>
    <xsl:value-of select="concat('@LP',$nl)"/>
    <xsl:value-of select="concat('@Tbl',$nl)"/>
    <xsl:value-of select="concat('rule {yes }',$nl)"/>
    <xsl:value-of select="concat(fcn:tbl-format('h','A,B,C,D,E'),$nl)"/>
    <xsl:value-of select="concat(fcn:tbl-format('d','A,B,C,D,E'),$nl)"/>
    <xsl:value-of select="concat('{',$nl)"/>
    <xsl:value-of select="concat('@Rowh',$nl)"/>
    <xsl:value-of select="concat('    A {Name}',$nl)"/>
    <xsl:value-of select="concat('    B {Typ}',$nl)"/>
    <xsl:value-of select="concat('    C {Default}',$nl)"/>
    <xsl:value-of select="concat('    D {Nullable}',$nl)"/>
    <xsl:value-of select="concat('    E {Kommentar}',$nl)"/>
    <xsl:apply-templates select="domain[@schema = $schema]"/>
    <xsl:value-of select="concat('}',$nl)"/>
    <xsl:value-of select="concat('@LP',$nl)"/>
    <xsl:value-of select="concat('@End @SubSection',$nl,$nl)"/>
  </xsl:template>

  
  <xsl:template match="domain">
    <xsl:value-of select="concat('@Rowd',$nl)"/>
    <xsl:value-of select="concat('    A {',fcn:format-name(@name),'}',$nl)"/>
    <xsl:value-of select="concat('    B {',@type,'}',$nl)"/>
    <xsl:value-of select="concat('    C {',default/text(),'}',$nl)"/>
    <xsl:value-of select="concat('    D {',@nullable,'}',$nl)"/>
    <xsl:value-of select="concat('    E {',fcn:replace(comment/text(),',',' @LP '),'}',$nl)"/>
  </xsl:template>

  
  <xsl:template match="sequences">
    <xsl:param name="schema"/>
    <xsl:value-of select="concat('@SubSection',$nl)"/>
    <xsl:value-of select="concat('@Title { Sequences im Schema ',fcn:format-name($schema),'}',$nl)"/>
    <xsl:value-of select="concat('@NewPage { Yes }',$nl)"/>
    <xsl:value-of select="concat('@Begin',$nl)"/>
    <xsl:value-of select="concat('@LP',$nl)"/>
    <xsl:value-of select="concat('@Tbl',$nl)"/>
    <xsl:value-of select="concat('rule {yes }',$nl)"/>
    <xsl:value-of select="concat(fcn:tbl-format('h','A,B,C,D,E,F'),$nl)"/>
    <xsl:value-of select="concat(fcn:tbl-format('d','A,B,C,D,E,F'),$nl)"/>
    <xsl:value-of select="concat('{',$nl)"/>
    <xsl:value-of select="concat('@Rowh',$nl)"/>
    <xsl:value-of select="concat('    A {Name}',$nl)"/>
    <xsl:value-of select="concat('    B {Typ}',$nl)"/>
    <xsl:value-of select="concat('    C {Min}',$nl)"/>
    <xsl:value-of select="concat('    D {Max}',$nl)"/>
    <xsl:value-of select="concat('    E {Incr}',$nl)"/>
    <xsl:value-of select="concat('    F {Kommentar}',$nl)"/>
    <xsl:apply-templates select="sequence[@schema = $schema]"/>
    <xsl:value-of select="concat('}',$nl)"/>
    <xsl:value-of select="concat('@LP',$nl)"/>
    <xsl:value-of select="concat('@End @SubSection',$nl,$nl)"/>
  </xsl:template>


  <xsl:template match="sequence">
    <xsl:value-of select="concat('@Rowd',$nl)"/>
    <xsl:value-of select="concat('    A {',fcn:format-name(@name),'}',$nl)"/>
    <xsl:value-of select="concat('    B {',@type,'}',$nl)"/>
    <xsl:value-of select="concat('    C {',config/@min,'}',$nl)"/>
    <xsl:value-of select="concat('    D {',config/@max,'}',$nl)"/>
    <xsl:value-of select="concat('    E {',config/@increment,'}',$nl)"/>
    <xsl:value-of select="concat('    F {',fcn:replace(comment/text(),',',', @LP '),'}',$nl)"/>
  </xsl:template>


  
  <xsl:template match="tables">
    <xsl:param name="schema"/>
    <xsl:value-of select="concat('@SubSection',$nl)"/>
    <xsl:value-of select="concat('@Title { Tabellen im Schema ',fcn:format-name($schema),'}',$nl)"/>
    <xsl:value-of select="concat('@NewPage { Yes }',$nl)"/>
    <xsl:value-of select="concat('@Begin',$nl)"/>
    <xsl:value-of select="concat('@BeginSubSubSections',$nl,$nl)"/>
    <xsl:apply-templates select="table[@schema = $schema]"/>
    <xsl:value-of select="concat('@EndSubSubSections',$nl,$nl)"/>
    <xsl:value-of select="concat('@End @SubSection',$nl,$nl)"/>
  </xsl:template>

  
  <xsl:template match="table">
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="table" select="@name"/>
    <xsl:variable name="primary">
      <xsl:apply-templates select="primary"/>
    </xsl:variable>
    <xsl:value-of select="concat('@SubSubSection',$nl)"/>
    <xsl:value-of select="concat('@Title { Table ',fcn:format-name(@name),'}',$nl)"/>
    <xsl:value-of select="concat('@NewPage { No }',$nl)"/>
    <xsl:value-of select="concat('@Begin',$nl)"/>
    <xsl:apply-templates select="columns">
      <xsl:with-param name="schema" select="$schema"/>
      <xsl:with-param name="table" select="$table"/>
      <xsl:with-param name="primary" select="$primary"/>
    </xsl:apply-templates>
    <xsl:value-of select="concat('@End @SubSubSection',$nl,$nl)"/>
  </xsl:template>

  
  <xsl:template match="columns">
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:param name="primary"/>
    <xsl:value-of select="concat('@LP',$nl)"/>
    <xsl:value-of select="concat('@Tbl',$nl)"/>
    <xsl:value-of select="concat('rule {yes }',$nl)"/>
    <xsl:value-of select="concat(fcn:tbl-format('h','A,B,C,D,E'),$nl)"/>
    <xsl:value-of select="concat(fcn:tbl-format('d','A,B,C,D,E'),$nl)"/>
    <xsl:value-of select="concat('{',$nl)"/>
    <xsl:value-of select="concat('@Rowh',$nl)"/>
    <xsl:value-of select="concat('    A {Name}',$nl)"/>
    <xsl:value-of select="concat('    B {Typ}',$nl)"/>
    <xsl:value-of select="concat('    C {Nullable}',$nl)"/>
    <xsl:value-of select="concat('    D {Kommentar}',$nl)"/>
    <xsl:value-of select="concat('    E {Referenz}',$nl)"/>
    <xsl:apply-templates select="column">
      <xsl:with-param name="schema" select="$schema"/>
      <xsl:with-param name="table" select="$table"/>
      <xsl:with-param name="primary" select="$primary"/>
    </xsl:apply-templates>
    <xsl:value-of select="concat('}',$nl)"/>
    <xsl:value-of select="concat('@LP',$nl)"/>
  </xsl:template>

  
  <xsl:template match="column">
    <xsl:param name="schema"/>
    <xsl:param name="table"/>
    <xsl:param name="primary"/>
    <xsl:variable name="column" select="@name"/>
    <xsl:variable name="column-name" select="fcn:format-name($column)"/>
    <xsl:variable name="foreign">
      <xsl:apply-templates select="//reference/source[@schema = $schema and  @table = $table]/../foreign">
        <xsl:with-param name="column" select="$column"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="format" select="fcn:if-contains-else($primary,@name,'@Rowh','@Rowd')"/>
    <xsl:value-of select="concat($format,$nl)"/>
    <xsl:value-of select="concat('    A {',$column-name,'}',$nl)"/>
    <xsl:value-of select="concat('    B {',fcn:format-name(@type),'}',$nl)"/>
    <xsl:value-of select="concat('    C {',@nullable,'}',$nl)"/>
    <xsl:value-of select="concat('    D {',comment/text(),'}',$nl)"/>
    <xsl:value-of select="concat('    E {',$foreign,'}',$nl)"/>
  </xsl:template>


  <xsl:template match="primary">
    <xsl:variable name="primary">
      <xsl:apply-templates select="key"/>
    </xsl:variable>
    <xsl:value-of select="$primary"/>
  </xsl:template>

  
  <xsl:template match="foreign">
    <xsl:param name="column"/>
    <xsl:variable name="schema" select="../target/@schema"/>
    <xsl:variable name="table"  select="../target/@table"/>
    <xsl:variable name="key">
      <xsl:apply-templates select="key"/>
    </xsl:variable>
    <xsl:if test="contains($key,$column)">
      <xsl:value-of select="concat(fcn:format-name($schema),'.',fcn:format-name($table))"/>
    </xsl:if>
  </xsl:template>

  
  
  <xsl:template match="key">
    <xsl:value-of select="concat(text(),'#')"/>
  </xsl:template>


  <xsl:template match="reference">
  </xsl:template>

  
</xsl:stylesheet> 
