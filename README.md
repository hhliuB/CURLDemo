# CURLDemo
使用libcurl实现接口的调用<br/>

若接口有通讯协议可添加👇配置<br/>
  /* 设置SSL 证书检测 */<br/>
  curl_easy_setopt(_curl, CURLOPT_SSL_VERIFYPEER, 0L);<br/>
  curl_easy_setopt(_curl, CURLOPT_SSL_VERIFYHOST, 0L);<br/>
  <br/>
