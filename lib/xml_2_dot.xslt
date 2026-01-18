<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn dyn">

  <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>

  <xsl:param name="debug"/>
  
  <xsl:param name="hist-schema"/>
  
  <xsl:param name="proc-hist-schema"/>
  
  <xsl:variable name="space">
    <xsl:text>                    </xsl:text>
  </xsl:variable>

  <xsl:variable name="tab">
    <xsl:text>    </xsl:text>
  </xsl:variable>

  <xsl:variable name="normal-tab">
    <xsl:text>             </xsl:text>
  </xsl:variable>

  <xsl:variable name="big-tab">
    <xsl:text>                   </xsl:text>
  </xsl:variable>

  <xsl:variable name="very-big-tab">
    <xsl:text>                        </xsl:text>
  </xsl:variable>

  <xsl:variable name="space-size" select="string-length($space)" />

  <xsl:variable name="nl">
    <xsl:text>&#10;</xsl:text>
  </xsl:variable>

  <xsl:variable name="shape-plain">
    <xsl:text>shape = "plain"</xsl:text>
 </xsl:variable>

  <xsl:variable name="table-header">
    <xsl:text>label=&lt;&lt;table border="1" cellborder="0" cellspacing="2" cellpadding="2"&gt;</xsl:text>
  </xsl:variable>

  <xsl:variable name="trb">
    <xsl:text>&lt;tr&gt;</xsl:text>
  </xsl:variable>

  <xsl:variable name="tre">
    <xsl:text>&lt;/tr&gt;</xsl:text>
  </xsl:variable>

  <xsl:variable name="tdb">
    <xsl:text>&lt;td&gt;</xsl:text>
  </xsl:variable>

  <xsl:variable name="tdab">
    <xsl:text>&lt;td align="left"&gt;</xsl:text>
  </xsl:variable>

  <xsl:variable name="tdabcs2">
    <xsl:text>&lt;td align="left" colspan="2"&gt;</xsl:text>
  </xsl:variable>

  <xsl:variable name="tdapb">
    <xsl:text>&lt;td align="left" port="#"&gt;</xsl:text>
  </xsl:variable>

  <xsl:variable name="tde">
    <xsl:text>&lt;/td&gt;</xsl:text>
  </xsl:variable>

  <xsl:variable name="bb">
    <xsl:text>&lt;b&gt;</xsl:text>
  </xsl:variable>

  <xsl:variable name="be">
    <xsl:text>&lt;/b&gt;</xsl:text>
  </xsl:variable>

  <xsl:variable name="ub">
    <xsl:text>&lt;u&gt;</xsl:text>
  </xsl:variable>

  <xsl:variable name="ue">
    <xsl:text>&lt;/u&gt;</xsl:text>
  </xsl:variable>

  <xsl:variable name="ib">
    <xsl:text>&lt;i&gt;</xsl:text>
  </xsl:variable>

  <xsl:variable name="ie">
    <xsl:text>&lt;/i&gt;</xsl:text>
  </xsl:variable>

  <xsl:variable name="hr">
    <xsl:text>&lt;hr/&gt;</xsl:text>
  </xsl:variable>

  <xsl:variable name="dim-schema" select="/model/schemas/schema[position() = 1]/@name"/>
  

  <xsl:include href="functions.xslt"/>

  
  <xsl:template name="get-references">
    <xsl:param name="filter"/>
    <xsl:for-each select="//table[dyn:evaluate($filter)]">
      <xsl:variable name="table" select="@name"/>
      <xsl:variable name="schema" select="@schema"/>
      <xsl:for-each select="//source[@schema = $schema and @table = $table]">
        <xsl:value-of select="concat('[',../@name,']')"/>  
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  
  <xsl:template match="model">

    <xsl:variable name="hist-message">
      <xsl:choose>
        <xsl:when test="$proc-hist-schema = 'only'">
          <xsl:value-of select="', nur Historisierung'"/>
        </xsl:when>
        <xsl:when test="$proc-hist-schema = 'no'">
          <xsl:value-of select="', ohne Historisierung'"/>
        </xsl:when>
        <xsl:when test="$proc-hist-schema = 'all'">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes">
            <xsl:value-of select="concat('invalid value [',$proc-hist-schema,'] for proc-hist-schema',$nl)"/>
          </xsl:message>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="filter">
      <xsl:choose>
        <xsl:when test="$proc-hist-schema = 'only'">
          <xsl:value-of select="'@schema = $hist-schema'"/>
        </xsl:when>
        <xsl:when test="$proc-hist-schema = 'no'">
            <xsl:value-of select="'@schema != $hist-schema'"/>
        </xsl:when>
        <xsl:when test="$proc-hist-schema = 'all'">
          <xsl:value-of select="'1 = 1'"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="has-references">
      <xsl:call-template name="get-references">
        <xsl:with-param name="filter" select="$filter"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:value-of select="concat('digraph ',fcn:format-name(@project),' {',$nl)"/>

    <xsl:value-of select="concat($tab,'orientation = ',$dq,'landscape',$dq,$nl)"/>
    <xsl:value-of select="concat($tab,'page        = ',$dq,'8,5',$dq,$nl)"/>
    <xsl:value-of select="concat($tab,'fontname    = ',$dq,'sans-serif',$dq,$nl,$nl)"/>

    <xsl:value-of select="concat($tab,'node [fontname = ',$dq,'sans-serif',$dq,']',$nl)"/>
    <xsl:value-of select="concat($tab,'edge [fontname = ',$dq,'sans-serif',$dq,']',$nl,$nl)"/>

    <xsl:variable name="label"
                  select="concat('Datenmodell ',fcn:format-name(@project),' (Version ',@version,$hist-message,')')"/>
    <xsl:value-of select="concat($tab,'graph [',$nl)"/>
    <xsl:value-of select="concat($tab,$tab,'fontsize = ',$dq,'24',$dq,$nl)"/>
    <xsl:value-of select="concat($tab,$tab,'rankdir  = ',$dq,'LR',$dq,$nl)"/>
    <xsl:value-of select="concat($tab,$tab,'label    = ',$dq,$label,$dq,$nl)"/>
    <xsl:value-of select="concat($tab,$tab,'labelloc = ',$dq,'t',$dq,$nl)"/>
    <xsl:value-of select="concat($tab,$tab,'splines  = ',$dq,'true',$dq,$nl)"/>
    <xsl:value-of select="concat($tab,']',$nl,$nl)"/>

    <xsl:apply-templates select="//table[dyn:evaluate($filter)]"/>

    <xsl:value-of select="concat('}',$nl,$nl)"/>

  </xsl:template>

  
  <xsl:template match="table">
    <xsl:variable name="pos" select="position()"/>
    <xsl:variable name="schema" select="@schema"/>
    <xsl:variable name="table" select="@name" />
    <xsl:variable name="unique">
      <xsl:value-of select="'#'"/>
      <xsl:for-each select="unique/key">
        <xsl:value-of select="concat(text(),'#')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="primary">
      <xsl:value-of select="'#'"/>
      <xsl:for-each select="primary/key">
        <xsl:value-of select="concat(text(),'#')"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="table-name" select="concat(fcn:format-name($schema),'.',fcn:format-name($table))" />

    <xsl:variable name="delim">
      <xsl:if test="$pos mod 2 = 0 and $proc-hist-schema = 'only'">
        <xsl:variable name="prev-schema">
          <xsl:for-each select="//table[@schema = $hist-schema]">
            <xsl:if test="position() = $pos - 1">
              <xsl:value-of select="@schema"/>
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="prev-table">
          <xsl:for-each select="//table[@schema = $hist-schema]">
            <xsl:if test="position() = $pos - 1">
              <xsl:value-of select="@name"/>
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>
        
        <xsl:value-of select="concat('    ',$dq,fcn:format-name($prev-schema),'.',fcn:format-name($prev-table),$dq,' -&gt; ',
                              $dq,fcn:format-name($schema),'.',fcn:format-name($table),$dq,
                              ' [style=invis]',$nl,$nl)"/>
      </xsl:if>
    </xsl:variable>


    <xsl:value-of select="concat($tab,$dq,$table-name,$dq,' [',$nl)"/>
    <xsl:value-of select="concat($tab,$tab,$shape-plain,$nl)"/>
    <xsl:value-of select="concat($tab,$tab,$table-header,$nl)"/>

    <xsl:value-of select="concat($big-tab,$trb,$nl)"/>
    <xsl:value-of select="concat($very-big-tab,$tdabcs2,$bb,$table-name,$be,$tde,$nl)"/>
    <xsl:value-of select="concat($big-tab,$tre,$nl)"/>

    <xsl:value-of select="concat($big-tab,$hr,$nl)"/>

    <xsl:apply-templates select="columns/column" mode="define">
      <xsl:with-param name="schema"  select="$schema" />
      <xsl:with-param name="table"   select="$table" />
      <xsl:with-param name="unique"  select="$unique" />
      <xsl:with-param name="primary" select="$primary" />
    </xsl:apply-templates>

    <xsl:value-of select="concat($normal-tab,'&lt;/table&gt;&gt;',$nl)"/>
    <xsl:value-of select="concat($tab,']',$nl,$nl)"/>

    <xsl:value-of select="$delim"/>
    <xsl:apply-templates select="//reference/source[@schema = $schema and @table = $table]/.."/>

  </xsl:template>

  
  <xsl:template match="column" mode="define">
    <xsl:param name="schema" />
    <xsl:param name="table" />
    <xsl:param name="unique" />
    <xsl:param name="primary" />
    <xsl:variable name="name" select="@name" />
    <xsl:variable name="column" select="fcn:format-name(@name)" />
    <xsl:variable name="type" select="fcn:format-name(@type)" />
    <xsl:variable name="tdaptnb" select="fcn:replace($tdapb,'#',concat('tgt',position()))" />
    <xsl:variable name="tdapsnb" select="fcn:replace($tdapb,'#',concat('src',position()))" />
    <xsl:variable name="target" select="//reference/source[@schema = $schema and @table = $table]/../target/@table" />

    <xsl:choose>
      <xsl:when test="contains($unique,$name)">
        <xsl:value-of select="concat($big-tab,$trb,$nl)" />

        <xsl:value-of select="concat($very-big-tab,$tdaptnb,$ub,$column,$ue,$tde,$nl)" />

        <xsl:choose>
          <xsl:when test="$target != ''">
            <xsl:value-of select="concat($very-big-tab,$tdapsnb,$ub,$type,$ue,$tde,$nl)" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat($very-big-tab,$tdab,$ub,$type,$ue,$tde,$nl)" />
          </xsl:otherwise>
        </xsl:choose>

        <xsl:value-of select="concat($big-tab,$tre,$nl)" />
      </xsl:when>
      <xsl:when test="contains($primary,$name)">
        <xsl:value-of select="concat($big-tab,$trb,$nl)" />

        <xsl:value-of select="concat($very-big-tab,$tdaptnb,$bb,$column,$be,$tde,$nl)" />

        <xsl:choose>
          <xsl:when test="$target != ''">
            <xsl:value-of select="concat($very-big-tab,$tdapsnb,$bb,$type,$be,$tde,$nl)" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat($very-big-tab,$tdab,$bb,$type,$be,$tde,$nl)" />
          </xsl:otherwise>
        </xsl:choose>

        <xsl:value-of select="concat($big-tab,$tre,$nl)" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat($big-tab,$trb,$nl)" />
        <xsl:value-of select="concat($very-big-tab,$tdab,$column,$tde,$nl)" />

        <xsl:choose>
          <xsl:when test="$target != ''">
            <xsl:value-of select="concat($very-big-tab,$tdapsnb,$type,$tde,$nl)" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat($very-big-tab,$tdab,$type,$tde,$nl)" />
          </xsl:otherwise>
        </xsl:choose>

        <xsl:value-of select="concat($big-tab,$tre,$nl)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="reference">
    <xsl:variable name="source-table"       select="source/@table"/>
    <xsl:variable name="source-table-name"  select="fcn:format-name($source-table)"/>
    <xsl:variable name="source-schema"      select="source/@schema"/>
    <xsl:variable name="source-schema-name" select="fcn:format-name($source-schema)"/>
    <xsl:variable name="target-table"       select="target/@table" />
    <xsl:variable name="target-table-name"  select="fcn:format-name($target-table)" />
    <xsl:variable name="target-schema"      select="target/@schema" />
    <xsl:variable name="target-schema-name" select="fcn:format-name($target-schema)" />
    <xsl:variable name="key"                select="foreign/key/text()" />
    <xsl:variable name="key-name"           select="fcn:format-name($key)" />
    <xsl:variable name="target-number">
      <xsl:apply-templates select="//table[@name = $target-table and @schema = $target-schema]/columns/column"
                           mode="reference">
        <xsl:with-param name="column" select="$key" />
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="source-number">
      <xsl:apply-templates select="//table[@name = $source-table and @schema = $source-schema]/columns/column"
                           mode="reference">
        <xsl:with-param name="column" select="$key" />
      </xsl:apply-templates>
    </xsl:variable>

    <xsl:if test="$debug = 1">
      <xsl:value-of select="concat('// table=',$source-table-name,' target-table=',$target-table-name,
                            ' target-schema=',$target-schema-name,$nl)" />
      <xsl:value-of select="concat('// key=',$key-name,' source-number=',$source-number,
                            ' target-number=',$target-number,$nl)" />
    </xsl:if>

    
    <xsl:value-of select="concat($tab,$dq,$source-schema-name,'.',$source-table-name,$dq,':src',$source-number,'  -> ',
                          $dq,$target-schema-name,'.',$target-table-name,$dq,':tgt',$target-number,' [',$nl)" />
    <xsl:value-of select="concat($normal-tab,'minlen     = 3.0',$nl)" />
    <xsl:value-of select="concat($normal-tab,'headlabel  = ',$dq,'n ',$dq,$nl)" />
    <xsl:value-of select="concat($normal-tab,'taillabel  = ',$dq,' 1',$dq,$nl)" />
    <xsl:value-of select="concat($tab,']',$nl,$nl)" />
  </xsl:template>


  <xsl:template match="column" mode="reference">
    <xsl:param name="column" />
    <xsl:if test="$column = @name">
      <xsl:value-of select="position()" />
    </xsl:if>
  </xsl:template>
  
  
</xsl:stylesheet> 
