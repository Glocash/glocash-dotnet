<%@ Page Language="C#"%>

<!DOCTYPE html>

<%
    
/**
 * 经典模式
 * 技术联系人 陈荣江 17602115638 微信同号
 * 文档地址 https://portal.glocash.com/merchant/index/document
 * 商户后台 https://portal.glocash.com/merchant/index/login
 *
 */

/**
    * 信用卡测试卡 其他apm支付需自己测试
    *   Visa | 4907639999990022 | 12/2020 | 029 paid
    *   MC   | 5546989999990033 | 12/2020 | 464 paid
    *   Visa | 4000000000000002 | 01/2022 | 237 | 14  3ds paid
    *   Visa | 4000000000000028 | 03/2022 | 999 | 54  3ds paid
    *   Visa | 4000000000000051 | 07/2022 | 745 | 94  3ds paid
    *   MC   | 5200000000000007 | 01/2022 | 356 | 34  3ds paid
    *   MC   | 5200000000000023 | 03/2022 | 431 | 74  3ds paid
    *   MC   | 5200000000000106 | 04/2022 | 578 | 104 3ds paid
    *
    *  想测试失败 可以填错年月日或者ccv即可
    */

//TODO 请仔细查看TODO的注释 请仔细查看TODO的注释 请仔细查看TODO的注释  

String sandbox_url= "https://sandbox.glocash.com/gateway/payment/index"; //测试地址
String live_url = "https://pay.glocash.com/gateway/payment/index"; //正式地址

//秘钥 测试地址请用测试秘钥 正式地址用正式秘钥 请登录商户后台查看
String sandbox_key = ""; //TODO 测试秘钥 商户后台查看
String live_key = ""; //TODO 正式秘钥 商户后台查看(必须材料通过以后才能使用)

//当前时间戳
DateTime utctemp = DateTime.UtcNow;
TimeSpan ts = utctemp - new DateTime(1970, 1, 1, 0, 0, 0, 0);
String untime = Convert.ToInt64(ts.TotalSeconds).ToString();

Random rand = new Random();

String invoicetemp = utctemp.Year + (utctemp.Month < 10 ? "0" + utctemp.Month.ToString() : utctemp.Month.ToString())
                    + (utctemp.Day < 10 ? "0" + utctemp.Day.ToString() : utctemp.Day.ToString())
                    + (utctemp.Hour < 10 ? "0" + utctemp.Hour.ToString() : utctemp.Hour.ToString())
                    + (utctemp.Minute < 10 ? "0" + utctemp.Minute.ToString() : utctemp.Minute.ToString())
                    + (utctemp.Second < 10 ? "0" + utctemp.Second.ToString() : utctemp.Second.ToString());

//支付参数
var data = new NameValueCollection();
data["REQ_SANDBOX"]  = "0"; //TODO 是否开启测试模式 注意秘钥是否对应
data["REQ_EMAIL"] = "rongjiang.chen@witsion.com"; //TODO 需要换成自己的 商户邮箱 商户后台申请的邮箱
data["REQ_TIMES"]    = untime; //请求时间
data["REQ_INVOICE"] = "TEST" + invoicetemp + rand.Next(1000, 9999); //订单号
data["BIL_METHOD"]   = "L01"; //请求方式
data["CUS_EMAIL"]    = "rongjiang.chen@witsion.com"; //客户邮箱
data["BIL_PRICE"]    = "0.1"; //价格
data["BIL_CURRENCY"] = "USD"; //币种
data["BIL_CC3DS"]    = "0"; //是否开启3ds 1 开启 0 不开启
data["URL_SUCCESS" ]  = "http://hs.crjblog.cn/success.php";//支付成功跳转页面
data["URL_FAILED"]   = "http://hs.crjblog.cn/failed.php"; //支付失败跳转页面
data["URL_NOTIFY"]   = "http://hs.crjblog.cn/notify.php"; //异步回调跳转页面

//$data['BIL_PRCCODE']  = 0; //电话支付相关参数 信用卡不需要填写
//更多支付参数请参考文档 经典模式->附录2：付款请求参数表
//签名
String url = data["REQ_SANDBOX"]=="1" ? sandbox_url : live_url;//根据REQ_SANDBOX调整地址
String key = data["REQ_SANDBOX"]=="1" ?sandbox_key: live_key;//根据REQ_SANDBOX调整秘钥

String reg_sign = key + data["REQ_TIMES"] + data["REQ_EMAIL"] + data["REQ_INVOICE"] + data["CUS_EMAIL"] + data["BIL_METHOD"] + data["BIL_PRICE"] + data["BIL_CURRENCY"];
byte[] bytes = Encoding.UTF8.GetBytes(reg_sign);
byte[] hash = System.Security.Cryptography.SHA256Managed.Create().ComputeHash(bytes);
StringBuilder builder = new StringBuilder();
for (int i = 0; i < hash.Length; i++)
{
    builder.Append(hash[i].ToString("X2"));
}
data.Add("REQ_SIGN", builder.ToString().ToLower());

try
{
    using (System.IO.StreamWriter file = new System.IO.StreamWriter(HttpRuntime.AppDomainAppPath.ToString() + @"\ccDirect.log", true))
    {
        file.WriteLine(DateTime.UtcNow);
        file.WriteLine(url);
        foreach (string keys in data)
        {
            foreach (string vals in data.GetValues(keys))
            {
                file.WriteLine(String.Format("{0}:{1}", keys, vals));
            }
        }
        file.WriteLine("");
        file.Close();
    }

    if (url.ToLower().Contains("https://"))
    {
        System.Net.ServicePointManager.ServerCertificateValidationCallback += (s, cert, chain, sslPolicyErrors) => true;
        System.Net.ServicePointManager.SecurityProtocol = System.Net.SecurityProtocolType.Tls12 | System.Net.SecurityProtocolType.Tls11 | System.Net.SecurityProtocolType.Tls;  
    }
    var client = new System.Net.WebClient();   //根据实际封装请求
    var response = client.UploadValues(url, data);
    var responseString = Encoding.Default.GetString(response);
    var js = new System.Web.Script.Serialization.JavaScriptSerializer();
    Dictionary<String, String> parseData = js.Deserialize<Dictionary<String, String>>(responseString);

    string sValue = "";
    if (parseData.TryGetValue("REQ_ERROR", out sValue))
    {
        foreach (KeyValuePair<String, String> kvp in parseData)
        {
            Response.Write("<pre>");
            Response.Write(String.Format("{0}:{1}", kvp.Key, kvp.Value));
            Response.Write("</pre>");
        }
        return;
    }


    using (System.IO.StreamWriter file = new System.IO.StreamWriter(HttpRuntime.AppDomainAppPath.ToString() + @"ccDirect.log", true))
    {
        file.WriteLine(responseString);
        foreach (KeyValuePair<String, String> kvp in parseData)
        {
            file.WriteLine(String.Format("{0}:{1}", kvp.Key, kvp.Value));
        }
        file.WriteLine("");
        file.Close();
    }


    if (responseString.Length > 0 && parseData.Count > 0)
    {
        Response.Redirect(parseData["URL_PAYMENT"], false); 
    }
    else
    {
        Response.Write("<pre>");
        Response.Write(responseString);
        Response.Write("</pre>");
        foreach (KeyValuePair<String, String> kvp in parseData)
        {
            Response.Write("<pre>");
            Response.Write(String.Format("{0}:{1}", kvp.Key, kvp.Value));
            Response.Write("</pre>");
        }
    }
    
}
catch (Exception e)
{
    Response.Write("<pre>");
    Response.Write(e.Message.ToString());
    Response.Write("</pre>");
}

%>

