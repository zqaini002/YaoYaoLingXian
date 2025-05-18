import http from '@ohos.net.http';
import { storage } from './StorageUtils';

// 请求方法枚举
export enum RequestMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE'
}

// 服务器基础URL
const BASE_URL = 'http://192.168.31.25:8080/api';
// 请求超时时间（毫秒）
const TIMEOUT = 10000;

/**
 * 发送HTTP请求
 * 
 * @param method 请求方法
 * @param url 请求路径（不包含BASE_URL）
 * @param params 请求参数
 * @param data 请求体数据
 * @returns Promise<T> 响应数据
 */
export async function request<T>(
  method: RequestMethod,
  url: string,
  params: Record<string, string> = {},
  data?: any
): Promise<T> {
  try {
    // 构建请求URL
    let fullUrl = `${BASE_URL}${url}`;
    
    // 添加查询参数
    if (Object.keys(params).length > 0) {
      const queryString = Object.entries(params)
        .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
        .join('&');
      fullUrl += `?${queryString}`;
    }
    
    console.info(`[HTTP ${method}] ${fullUrl}`);
    
    // 创建HTTP请求客户端
    const httpRequest = http.createHttp();
    
    // 获取认证令牌
    const token = await storage.get('token');
    
    // 设置请求头
    let headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    
    if (token) {
      // 创建新对象避免索引访问
      headers = {
        ...headers,
        'Authorization': `Bearer ${token}`
      };
    }
    
    // 设置请求选项
    const options: http.HttpRequestOptions = {
      method: method,
      header: headers,
      readTimeout: TIMEOUT,
      connectTimeout: TIMEOUT,
      extraData: data ? JSON.stringify(data) : undefined
    };
    
    if (data) {
      console.info(`[HTTP ${method}] 请求数据:`, JSON.stringify(data));
    }
    
    // 发送请求
    const response = await httpRequest.request(fullUrl, options);
    
    // 请求完成后释放资源
    httpRequest.destroy();
    
    console.info(`[HTTP ${method}] 响应状态码: ${response.responseCode}`);
    
    // 检查响应状态码
    if (response.responseCode >= 200 && response.responseCode < 300) {
      const responseData = response.result as string;
      console.info(`[HTTP ${method}] 响应数据:`, responseData);
      
      // 尝试解析JSON
      try {
        const jsonData = JSON.parse(responseData);
        return jsonData as T;
      } catch (parseError) {
        console.error(`[HTTP ${method}] 解析响应JSON失败:`, parseError);
        throw new Error('解析响应数据失败');
      }
    } else {
      // 处理HTTP错误
      console.error(`[HTTP ${method}] 请求失败, 状态码: ${response.responseCode}, 响应: ${response.result}`);
      
      let errorMessage = `请求失败 (${response.responseCode})`;
      
      // 尝试从错误响应中获取更详细信息
      try {
        const errorData = JSON.parse(response.result as string);
        if (errorData.message) {
          errorMessage = errorData.message;
        }
      } catch (e) {
        // 无法解析错误响应，使用默认错误消息
      }
      
      // 处理不同状态码
      switch (response.responseCode) {
        case 401:
          // 未授权，尝试刷新令牌或要求用户重新登录
          errorMessage = '登录已过期，请重新登录';
          break;
        case 403:
          errorMessage = '没有操作权限';
          break;
        case 404:
          errorMessage = '请求的资源不存在';
          break;
        case 500:
          errorMessage = '服务器内部错误，请稍后重试';
          break;
      }
      
      throw new Error(errorMessage);
    }
  } catch (error) {
    if (error instanceof Error) {
      console.error(`[HTTP ${method}] 请求异常:`, error.message);
      throw error;
    } else {
      console.error(`[HTTP ${method}] 未知异常:`, error);
      throw new Error('网络请求失败，请检查网络连接');
    }
  }
} 