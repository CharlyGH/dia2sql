<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:exslt="http://exslt.org/common"
                xmlns:fcn="http://exslt.org/functions"
                xmlns:dyn="http://exslt.org/dynamic"
                extension-element-prefixes="fcn dyn">

  
  <xsl:variable name="q">
    <xsl:text>&apos;</xsl:text>
  </xsl:variable>

  <xsl:variable name="dq">
    <xsl:text>&quot;</xsl:text>
  </xsl:variable>


  <fcn:function name="fcn:format-name" >
    <xsl:param name="source" />
    <xsl:variable name="prefix" select="substring-before($source,'_')" />
    <xsl:variable name="suffix" select="substring-after($source,'_')" />
    <xsl:variable name="target">
      <xsl:choose>
        <xsl:when test="contains($source,'_')">
          <xsl:value-of select="concat(fcn:to-capital-case($prefix),'_',fcn:format-name($suffix))" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:to-capital-case($source)" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="$target" />
    </fcn:result>
  </fcn:function>


  <fcn:function name="fcn:to-lower-case" >
    <xsl:param name="source" />
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ_'" />
    <fcn:result>
      <xsl:value-of select="translate($source, $uppercase, $lowercase)" />
    </fcn:result>
  </fcn:function>


  <fcn:function name="fcn:to-upper-case" >
    <xsl:param name="source" />
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ_'" />
    <fcn:result>
      <xsl:value-of select="translate($source, $lowercase, $uppercase)" />
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:to-capital-case" >
    <xsl:param name="source" />
    <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz_'" />
    <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ_'" />
    <xsl:variable name="head" select="translate(substring($source,1,1), $lowercase, $uppercase)" />
    <xsl:variable name="tail" select="translate(substring($source,2), $uppercase, $lowercase)" />
    <fcn:result>
      <xsl:value-of select="concat($head,$tail)" />
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:if-then-else" >
    <xsl:param name="le" />
    <xsl:param name="op" />
    <xsl:param name="ri" />
    <xsl:param name="then" />
    <xsl:param name="else" />
    <xsl:variable name="test" select="concat($q,dyn:evaluate('$le'),$q,dyn:evaluate(' $op '),$q,dyn:evaluate('$ri'),$q)"/>
    <xsl:variable name="result">
      <xsl:choose>
        <xsl:when test="dyn:evaluate($test)">
          <xsl:value-of select="$then" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$else" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="$result" />
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:if-contains-else" >
    <xsl:param name="lis" />
    <xsl:param name="el" />
    <xsl:param name="then" />
    <xsl:param name="else" />
    <xsl:variable name="result">
      <xsl:choose>
        <xsl:when test="contains($lis,$el)">
          <xsl:value-of select="$then" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$else" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="$result" />
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:replace" >
    <xsl:param name="source" />
    <xsl:param name="old" />
    <xsl:param name="new" />
    <xsl:variable name="target">
      <xsl:choose>
        <xsl:when test="contains($source,$old)">
          <xsl:value-of select="concat(substring-before($source,$old),$new,substring-after($source,$old))" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$source" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <fcn:result>
      <xsl:choose>
        <xsl:when test="contains($target,$old)">
          <xsl:value-of select="fcn:replace($target,$old,$new)" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$target" />
        </xsl:otherwise>
      </xsl:choose>
    </fcn:result>
  </fcn:function>


  <fcn:function name="fcn:replace-first" >
    <xsl:param name="source" />
    <xsl:param name="old" />
    <xsl:param name="new" />
    <xsl:variable name="target">
      <xsl:choose>
        <xsl:when test="contains($source,$old)">
          <xsl:value-of select="concat(substring-before($source,$old),$new,substring-after($source,$old))" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$source" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <fcn:result>
      <xsl:value-of select="$target" />
    </fcn:result>
  </fcn:function>

  
  <fcn:function name="fcn:get-project-value" >
    <xsl:param name="projectfile" />
    <xsl:param name="key" />
    <xsl:param name="basename" />

    <xsl:variable name="rawvalue" select="document($projectfile)/project/item[@name = $key]/@value"/>
    <xsl:variable name="value" select="fcn:replace($rawvalue,'{}',$basename)"/>
      
    <fcn:result>
      <xsl:value-of select="$value" />
    </fcn:result>
  </fcn:function>


  
</xsl:stylesheet> 
