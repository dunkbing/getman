//
//  Http.swift
//  getman
//
//  Created by Bùi Đặng Bình on 23/12/24.
//

func getStatusCodeDescription(_ code: Int) -> String {
    switch code {
    // 1xx Informational
    case 100:
        return
            "Continue. The server has received the request headers and the client should proceed to send the request body."
    case 101:
        return
            "Switching Protocols. The server is switching protocols according to the Upgrade header."
    case 102:
        return "Processing. The server is processing the request but no response is available yet."
    case 103:
        return "Early Hints. Used to return some response headers before final HTTP message."

    // 2xx Success
    case 200:
        return "Request successful. The server has responded as required."
    case 201:
        return "Created. The request has been fulfilled and a new resource has been created."
    case 202:
        return "Accepted. The request has been accepted for processing but not completed."
    case 203:
        return "Non-Authoritative Information. The returned information is from a cached copy."
    case 204:
        return "No Content. The request was successful but there is no content to return."
    case 205:
        return
            "Reset Content. The server has fulfilled the request and wants the client to reset the document view."
    case 206:
        return
            "Partial Content. The server is delivering only part of the resource due to a range header."
    case 207:
        return "Multi-Status. Multiple status codes for multiple status operations."
    case 208:
        return "Already Reported. The members of a DAV binding have already been enumerated."

    // 3xx Redirection
    case 300:
        return "Multiple Choices. Multiple options for the resource are available."
    case 301:
        return "Moved Permanently. The resource has been permanently moved to a new URL."
    case 302:
        return "Found. The resource has been temporarily moved to a different URL."
    case 303:
        return "See Other. The response can be found at a different URL using GET."
    case 304:
        return "Not Modified. The resource hasn't been modified since the last request."
    case 307:
        return
            "Temporary Redirect. The request should be repeated with another URL but future requests should use the original URL."
    case 308:
        return
            "Permanent Redirect. The request and all future requests should be repeated using another URL."

    // 4xx Client Errors
    case 400:
        return "Bad Request. The server cannot process the request due to client error."
    case 401:
        return "Unauthorized. Authentication is required and has failed or not been provided."
    case 402:
        return "Payment Required. Reserved for future use. Payment is required."
    case 403:
        return "Forbidden. The server understood the request but refuses to authorize it."
    case 404:
        return "Not Found. The requested resource could not be found on the server."
    case 405:
        return "Method Not Allowed. The request method is not supported for the requested resource."
    case 406:
        return
            "Not Acceptable. The requested resource is capable of generating only content not acceptable according to Accept headers."
    case 407:
        return "Proxy Authentication Required. Authentication with the proxy is required."
    case 408:
        return "Request Timeout. The server timed out waiting for the request."
    case 409:
        return "Conflict. The request conflicts with the current state of the server."
    case 410:
        return
            "Gone. The requested resource is no longer available and will not be available again."
    case 411:
        return "Length Required. The request did not specify the length of its content."
    case 412:
        return "Precondition Failed. The server does not meet one of the preconditions."
    case 413:
        return
            "Payload Too Large. The request is larger than the server is willing or able to process."
    case 414:
        return "URI Too Long. The URI provided was too long for the server to process."
    case 415:
        return
            "Unsupported Media Type. The request entity has a media type which the server does not support."
    case 416:
        return
            "Range Not Satisfiable. The client has asked for a portion of the file but the server cannot supply that portion."
    case 417:
        return
            "Expectation Failed. The server cannot meet the requirements of the Expect request-header field."
    case 418:
        return "I'm a teapot. The server refuses to brew coffee because it is a teapot."
    case 429:
        return "Too Many Requests. The user has sent too many requests in a given amount of time."

    // 5xx Server Errors
    case 500:
        return "Internal Server Error. The server encountered an unexpected condition."
    case 501:
        return
            "Not Implemented. The server does not support the functionality required to fulfill the request."
    case 502:
        return "Bad Gateway. The server received an invalid response from the upstream server."
    case 503:
        return
            "Service Unavailable. The server is currently unavailable (overloaded or down for maintenance)."
    case 504:
        return
            "Gateway Timeout. The server did not receive a timely response from the upstream server."
    case 505:
        return
            "HTTP Version Not Supported. The server does not support the HTTP protocol version used in the request."
    case 506:
        return
            "Variant Also Negotiates. Transparent content negotiation for the request results in a circular reference."
    case 507:
        return
            "Insufficient Storage. The server is unable to store the representation needed to complete the request."
    case 508:
        return "Loop Detected. The server detected an infinite loop while processing the request."
    case 510:
        return
            "Not Extended. Further extensions to the request are required for the server to fulfill it."
    case 511:
        return
            "Network Authentication Required. The client needs to authenticate to gain network access."

    default:
        return "Unknown status code."
    }
}

func getStatusCodeShortDescription(_ code: Int) -> String {
    switch code {
    // 1xx Informational
    case 100: return "Continue"
    case 101: return "Switching Protocols"
    case 102: return "Processing"
    case 103: return "Early Hints"

    // 2xx Success
    case 200: return "OK"
    case 201: return "Created"
    case 202: return "Accepted"
    case 203: return "Non-Authoritative Information"
    case 204: return "No Content"
    case 205: return "Reset Content"
    case 206: return "Partial Content"
    case 207: return "Multi-Status"
    case 208: return "Already Reported"

    // 3xx Redirection
    case 300: return "Multiple Choices"
    case 301: return "Moved Permanently"
    case 302: return "Found"
    case 303: return "See Other"
    case 304: return "Not Modified"
    case 307: return "Temporary Redirect"
    case 308: return "Permanent Redirect"

    // 4xx Client Errors
    case 400: return "Bad Request"
    case 401: return "Unauthorized"
    case 402: return "Payment Required"
    case 403: return "Forbidden"
    case 404: return "Not Found"
    case 405: return "Method Not Allowed"
    case 406: return "Not Acceptable"
    case 407: return "Proxy Authentication Required"
    case 408: return "Request Timeout"
    case 409: return "Conflict"
    case 410: return "Gone"
    case 411: return "Length Required"
    case 412: return "Precondition Failed"
    case 413: return "Payload Too Large"
    case 414: return "URI Too Long"
    case 415: return "Unsupported Media Type"
    case 416: return "Range Not Satisfiable"
    case 417: return "Expectation Failed"
    case 418: return "I'm a teapot"
    case 429: return "Too Many Requests"

    // 5xx Server Errors
    case 500: return "Internal Server Error"
    case 501: return "Not Implemented"
    case 502: return "Bad Gateway"
    case 503: return "Service Unavailable"
    case 504: return "Gateway Timeout"
    case 505: return "HTTP Version Not Supported"
    case 506: return "Variant Also Negotiates"
    case 507: return "Insufficient Storage"
    case 508: return "Loop Detected"
    case 510: return "Not Extended"
    case 511: return "Network Authentication Required"

    default: return "Unknown Status"
    }
}
