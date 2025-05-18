import { Task, PageResponse, RequestMethod, ApiResponse, QueryParams } from '../model/CommonTypes';
import { request, EmptyParams, RequestData } from './ApiService';

/**
 * 任务查询参数接口
 */
export interface TaskQueryParams extends QueryParams {
  page?: number;
  size?: number;
  days?: number;
  userId?: number;
  keyword?: string;
}

/**
 * 进度记录接口
 */
export interface Progress {
  id: number;
  dreamId?: number;
  taskId?: number;
  userId: number;
  description: string;
  images?: string;
  createdAt: string;
}

/**
 * 获取用户全部任务
 * 
 * @param userId 用户ID
 * @param page 页码（可选）
 * @param size 每页大小（可选）
 * @returns 任务列表分页结果
 */
export function getAllTasks(userId: number, page: number = 0, size: number = 20): Promise<PageResponse<Task>> {
  const params: TaskQueryParams = { page, size };
  try {
    return request<PageResponse<Task>>(
      RequestMethod.GET,
      `/tasks/user/${userId}/pageable`,
      params
    );
  } catch (error) {
    console.error(`获取用户全部任务失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`获取用户全部任务失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 根据任务状态获取用户任务
 * 
 * @param userId 用户ID
 * @param status 状态：0-待开始，1-进行中，2-已完成，3-已延期
 * @returns 任务列表
 */
export function getTasksByStatus(userId: number, status: number): Promise<Task[]> {
  try {
    return request<Task[]>(
      RequestMethod.GET,
      `/tasks/user/${userId}/status/${status}`
    );
  } catch (error) {
    console.error(`获取用户状态为${status}的任务失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`获取用户状态为${status}的任务失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 获取用户今日任务
 * 
 * @param userId 用户ID
 * @param page 页码
 * @param size 每页大小
 * @returns 今日任务列表
 */
export function getTodayTasks(userId: number, page: number = 0, size: number = 5): Promise<PageResponse<Task>> {
  const params: TaskQueryParams = { page, size };
  try {
    return request<PageResponse<Task>>(
      RequestMethod.GET, 
      `/tasks/user/${userId}/today`, 
      params
    );
  } catch (error) {
    console.error(`获取今日任务列表失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`获取今日任务列表失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 获取用户即将到期的任务列表
 * 
 * @param userId 用户ID
 * @param days 天数
 * @param page 页码
 * @param size 每页大小
 * @returns 即将到期的任务列表
 */
export function getUpcomingTasks(userId: number, days: number = 7, page: number = 0, size: number = 5): Promise<PageResponse<Task>> {
  const params: TaskQueryParams = { days, page, size };
  try {
    return request<PageResponse<Task>>(
      RequestMethod.GET, 
      `/tasks/user/${userId}/upcoming`, 
      params
    );
  } catch (error) {
    console.error(`获取即将到期任务列表失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`获取即将到期任务列表失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 获取任务的进度记录
 * 
 * @param taskId 任务ID
 * @returns 进度记录列表
 */
export function getTaskProgress(taskId: number): Promise<Progress[]> {
  try {
    return request<Progress[]>(
      RequestMethod.GET,
      `/progress/task/${taskId}`
    );
  } catch (error) {
    console.error(`获取任务进度记录失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`获取任务进度记录失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 添加任务进度记录
 * 
 * @param progress 进度记录对象
 * @returns 创建的进度记录
 */
export function addTaskProgress(progress: Progress): Promise<Progress> {
  try {
    // 创建符合接口的数据结构
    const queryParams: QueryParams = {};
    const requestData: RequestData = {
      taskId: progress.taskId,
      dreamId: progress.dreamId,
      userId: progress.userId,
      description: progress.description,
      // 由于RequestData不支持images字段，将其放在URL参数中
    };
    
    // 如果有图片，添加到URL参数中
    if (progress.images) {
      queryParams['images'] = progress.images;
    }
    
    return request<Progress>(
      RequestMethod.POST,
      `/progress`, // 使用后端真实的API路径
      queryParams,
      requestData
    );
  } catch (error) {
    console.error(`添加任务进度记录失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`添加任务进度记录失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 创建新任务
 * 
 * @param task 任务对象
 * @returns 创建的任务
 */
export function createTask(task: Task): Promise<Task> {
  try {
    // 创建符合接口的数据结构
    const queryParams: QueryParams = {};
    const requestData: RequestData = {
      id: task.id,
      userId: task.userId,
      dreamId: task.dreamId,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      // RequestData不支持以下字段，移到URL参数中
    };
    
    // 将不支持的字段添加到URL参数中
    if (task.startDate) queryParams['startDate'] = task.startDate;
    if (task.dueDate) queryParams['dueDate'] = task.dueDate;
    if (task.parentTaskId) queryParams['parentTaskId'] = task.parentTaskId;
    if (task.reminderTime) queryParams['reminderTime'] = task.reminderTime;
    
    return request<Task>(
      RequestMethod.POST,
      `/tasks`,
      queryParams,
      requestData
    );
  } catch (error) {
    console.error(`创建任务失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`创建任务失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 更新任务
 * 
 * @param id 任务ID
 * @param task 任务对象
 * @returns 更新后的任务
 */
export function updateTask(id: number, task: Task): Promise<Task> {
  try {
    // 创建符合接口的数据结构
    const queryParams: QueryParams = {};
    const requestData: RequestData = {
      id: task.id,
      userId: task.userId,
      dreamId: task.dreamId,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      // RequestData不支持以下字段，移到URL参数中
    };
    
    // 将不支持的字段添加到URL参数中
    if (task.startDate) queryParams['startDate'] = task.startDate;
    if (task.dueDate) queryParams['dueDate'] = task.dueDate;
    if (task.reminderTime) queryParams['reminderTime'] = task.reminderTime;
    if (task.parentTaskId) queryParams['parentTaskId'] = task.parentTaskId;
    
    return request<Task>(
      RequestMethod.PUT,
      `/tasks/${id}`,
      queryParams,
      requestData
    );
  } catch (error) {
    console.error(`更新任务失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`更新任务失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 根据ID获取任务详情
 * 
 * @param taskId 任务ID
 * @returns 任务详情
 */
export function getTaskById(taskId: number): Promise<Task> {
  try {
    return request<Task>(
      RequestMethod.GET,
      `/tasks/${taskId}`
    );
  } catch (error) {
    console.error(`获取任务详情失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`获取任务详情失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 更新任务状态
 * 
 * @param taskId 任务ID
 * @param status 新状态：0-待开始，1-进行中，2-已完成，3-已延期
 * @returns 更新后的任务
 */
export function updateTaskStatus(taskId: number, status: number): Promise<Task> {
  try {
    return request<Task>(
      RequestMethod.PUT,
      `/tasks/${taskId}/status/${status}`
    );
  } catch (error) {
    console.error(`更新任务状态失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`更新任务状态失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 删除任务
 * 
 * @param id 任务ID
 * @returns 无返回值
 */
export function deleteTask(id: number): Promise<void> {
  try {
    return request<void>(
      RequestMethod.DELETE,
      `/tasks/${id}`
    );
  } catch (error) {
    console.error(`删除任务失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`删除任务失败: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * 搜索任务
 * 
 * @param userId 用户ID
 * @param keyword 搜索关键词
 * @param page 页码
 * @param size 每页大小
 * @returns 任务列表分页结果
 */
export function searchTasks(userId: number, keyword: string, page: number = 0, size: number = 20): Promise<PageResponse<Task>> {
  const params: TaskQueryParams = { userId, keyword, page, size };
  try {
    return request<PageResponse<Task>>(
      RequestMethod.GET,
      `/tasks/search`,
      params
    );
  } catch (error) {
    console.error(`搜索任务失败: ${error instanceof Error ? error.message : String(error)}`);
    throw new Error(`搜索任务失败: ${error instanceof Error ? error.message : String(error)}`);
  }
} 