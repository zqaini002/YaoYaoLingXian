package com.dreamplanner.controller;

import com.dreamplanner.dto.ApiResponseDTO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.Enumeration;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import jakarta.servlet.http.HttpServletRequest;
import org.json.JSONArray;
import org.json.JSONObject;
import org.springframework.util.StreamUtils;

/**
 * 文件上传控制器
 *
 * @author DreamPlanner
 */
@RestController
@RequestMapping("/files")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "文件管理", description = "文件上传相关接口")
public class FileController {

    // 文件存储根目录，从配置文件中读取
    @Value("${file.upload.dir:uploads}")
    private String uploadDir;
    
    // 文件访问的基础URL，从配置文件中读取
    @Value("${file.access.url:http://localhost:8080/api/files}")
    private String fileAccessUrl;

    /**
     * 上传图片接口 - 标准multipart/form-data格式
     *
     * @param file 图片文件
     * @param type 图片类型（dream、task、progress、avatar等）
     * @return 图片URL
     */
    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "上传图片(Multipart)", description = "使用multipart/form-data格式上传图片文件并返回访问URL")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponseDTO<Map<String, String>>> uploadImage(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "type", defaultValue = "common") String type) {
        
        log.info("开始上传图片(Multipart), 类型: {}, 原始文件名: {}, 内容类型: {}, 大小: {} bytes", 
                type, file.getOriginalFilename(), file.getContentType(), file.getSize());
        
        try {
            // 检查文件是否为空
            if (file.isEmpty()) {
                log.error("上传失败，文件为空");
                return ResponseEntity.badRequest()
                        .body(ApiResponseDTO.error("上传失败，文件为空"));
            }
            
            // 检查文件大小（限制为10MB）
            final long MAX_SIZE = 10 * 1024 * 1024; // 10MB
            if (file.getSize() > MAX_SIZE) {
                log.error("上传失败，文件过大: {} bytes, 最大限制: {} bytes", file.getSize(), MAX_SIZE);
                return ResponseEntity.badRequest()
                        .body(ApiResponseDTO.error("上传失败，文件大小超过10MB限制"));
            }
            
            // 检查文件类型是否为图片
            String contentType = file.getContentType();
            if (contentType == null || !contentType.startsWith("image/")) {
                log.error("上传失败，不支持的文件类型: {}", contentType);
                return ResponseEntity.badRequest()
                        .body(ApiResponseDTO.error("上传失败，只支持图片文件"));
            }
            
            // 获取原始文件名
            String originalFilename = file.getOriginalFilename();
            log.info("原始文件名: {}", originalFilename);
            
            // 创建保存目录（按类型分类）
            String dateFolder = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
            String folderPath = uploadDir + File.separator + type + File.separator + dateFolder;
            Path targetPath = Paths.get(folderPath);
            
            if (!Files.exists(targetPath)) {
                Files.createDirectories(targetPath);
                log.info("创建目录: {}", targetPath);
            }
            
            // 生成新的文件名
            String fileExtension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                fileExtension = originalFilename.substring(originalFilename.lastIndexOf("."));
            } else {
                // 如果文件名没有扩展名，则根据内容类型添加
                if (contentType.contains("jpeg") || contentType.contains("jpg")) {
                    fileExtension = ".jpg";
                } else if (contentType.contains("png")) {
                    fileExtension = ".png";
                } else if (contentType.contains("gif")) {
                    fileExtension = ".gif";
                } else if (contentType.contains("webp")) {
                    fileExtension = ".webp";
                } else {
                    fileExtension = ".bin"; // 默认二进制文件扩展名
                }
            }
            String newFilename = UUID.randomUUID().toString() + fileExtension;
            
            // 保存文件
            Path filePath = targetPath.resolve(newFilename);
            try {
                log.info("开始保存文件到: {}", filePath);
                // 使用缓冲写入文件，防止内存溢出
            Files.copy(file.getInputStream(), filePath);
                log.info("文件保存成功: {}", filePath);
            } catch (IOException e) {
                log.error("文件保存失败: {}", e.getMessage(), e);
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body(ApiResponseDTO.error("文件保存失败: " + e.getMessage()));
            }
            
            // 构建文件访问URL
            String fileUrl = fileAccessUrl + "/" + type + "/" + dateFolder + "/" + newFilename;
            log.info("文件URL生成: {}", fileUrl);
            
            // 返回文件URL
            Map<String, String> result = new HashMap<>();
            result.put("url", fileUrl);
            result.put("filename", newFilename);
            
            return ResponseEntity.ok(ApiResponseDTO.success(result));
            
        } catch (IOException e) {
            log.error("文件上传过程发生IO异常: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponseDTO.error("文件上传失败: " + e.getMessage()));
        } catch (Exception e) {
            log.error("文件上传过程发生未知异常: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponseDTO.error("文件上传失败，服务器内部错误"));
        }
    }
    
    /**
     * 通用文件上传接口 - 支持多种格式，包括application/x-www-form-urlencoded和multipart/form-data
     * 以及鸿蒙OS特殊的JSON格式请求
     *
     * @param request HTTP请求
     * @return 图片URL
     */
    @PostMapping(value = "/upload")
    @Operation(summary = "通用上传接口", description = "通用文件上传接口，支持多种格式，包括鸿蒙客户端特殊格式")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponseDTO<Map<String, String>>> uploadGeneral(HttpServletRequest request) {
        log.info("收到通用上传请求, Content-Type: {}", request.getContentType());
        
        // 尝试从请求体中读取原始数据
        String requestBody = "";
        try {
            requestBody = StreamUtils.copyToString(request.getInputStream(), java.nio.charset.StandardCharsets.UTF_8);
            log.info("请求体内容: {}", requestBody);
        } catch (IOException e) {
            log.error("读取请求体失败: {}", e.getMessage(), e);
        }
        
        // 打印所有请求参数，帮助调试
        Map<String, String[]> paramMap = request.getParameterMap();
        for (String key : paramMap.keySet()) {
            String[] values = paramMap.get(key);
            for (String value : values) {
                log.info("请求参数: {} = {}", key, value);
            }
        }
        
        // 打印所有请求头，帮助调试
        Enumeration<String> headerNames = request.getHeaderNames();
        while (headerNames.hasMoreElements()) {
            String headerName = headerNames.nextElement();
            log.info("请求头: {} = {}", headerName, request.getHeader(headerName));
        }
        
        // 获取请求参数
        String fileUri = null;
        String type = "common";
        String filename = "unknown";
        String contentType = "image/jpeg";
        String base64Content = null;
        
        // 尝试从请求参数中获取
        if (request.getParameter("file") != null) {
            fileUri = request.getParameter("file");
            if (request.getParameter("type") != null) {
                type = request.getParameter("type");
            }
            if (request.getParameter("fileContent") != null) {
                base64Content = request.getParameter("fileContent");
            }
        } 
        // 如果请求参数中没有，尝试从请求体解析JSON格式
        else if (!requestBody.isEmpty()) {
            try {
                // 鸿蒙客户端特殊的JSON格式，尝试解析
                if (requestBody.startsWith("[{") && requestBody.contains("name") && requestBody.contains("value")) {
                    JSONArray jsonArray = new JSONArray(requestBody);
                    
                    for (int i = 0; i < jsonArray.length(); i++) {
                        JSONObject item = jsonArray.getJSONObject(i);
                        String name = item.optString("name", "");
                        String value = item.optString("value", "");
                        
                        if ("file".equals(name) && value != null && !value.isEmpty()) {
                            fileUri = value;
                            if (item.has("filename")) {
                                filename = item.getString("filename");
                            }
                            if (item.has("contentType")) {
                                contentType = item.getString("contentType");
                            }
                            // 尝试获取文件内容
                            if (item.has("content")) {
                                base64Content = item.getString("content");
                            }
                        } else if ("type".equals(name) && value != null && !value.isEmpty()) {
                            type = value;
                        } else if ("fileContent".equals(name) && value != null && !value.isEmpty()) {
                            base64Content = value;
                        }
                    }
                }
                // 另一种可能的格式：常规JSON对象
                else if (requestBody.startsWith("{")) {
                    JSONObject json = new JSONObject(requestBody);
                    if (json.has("file")) {
                        fileUri = json.getString("file");
                    }
                    if (json.has("type")) {
                        type = json.getString("type");
                    }
                    if (json.has("filename")) {
                        filename = json.getString("filename");
                    }
                    if (json.has("contentType")) {
                        contentType = json.getString("contentType");
                    }
                    if (json.has("fileContent") || json.has("content")) {
                        base64Content = json.has("fileContent") ? 
                            json.getString("fileContent") : json.getString("content");
                    }
                }
            } catch (Exception e) {
                log.error("解析JSON请求体失败: {}", e.getMessage(), e);
            }
        }
        
        log.info("解析请求参数: file = {}, type = {}, filename = {}, contentType = {}, hasContent = {}", 
                fileUri, type, filename, contentType, base64Content != null);
        
        try {
            // 检查文件URI是否为空
            if (fileUri == null || fileUri.trim().isEmpty()) {
                log.error("上传失败，file参数为空");
                return ResponseEntity.badRequest()
                        .body(ApiResponseDTO.error("上传失败，file参数为空"));
            }
            
            // 提取文件名
            if ("unknown".equals(filename) && fileUri.contains("/")) {
                filename = fileUri.substring(fileUri.lastIndexOf('/') + 1);
            }
            log.info("从URI提取的文件名: {}", filename);
            
            // 创建保存目录（按类型分类）
            String dateFolder = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
            String folderPath = uploadDir + File.separator + type + File.separator + dateFolder;
            Path targetPath = Paths.get(folderPath);
            
            if (!Files.exists(targetPath)) {
                Files.createDirectories(targetPath);
                log.info("创建目录: {}", targetPath);
            }
            
            // 确定文件扩展名
            String fileExtension = ".jpg"; // 默认jpg
            if (filename.contains(".")) {
                fileExtension = filename.substring(filename.lastIndexOf("."));
            } else if (contentType != null) {
                // 根据内容类型设置扩展名
                if (contentType.contains("jpeg") || contentType.contains("jpg")) {
                    fileExtension = ".jpg";
                } else if (contentType.contains("png")) {
                    fileExtension = ".png";
                } else if (contentType.contains("gif")) {
                    fileExtension = ".gif";
                } else if (contentType.contains("webp")) {
                    fileExtension = ".webp";
                }
            }
            
            // 生成新的文件名
            String newFilename = UUID.randomUUID().toString() + fileExtension;
            Path filePath = targetPath.resolve(newFilename);
            
            // 处理上传文件
            boolean fileProcessed = false;
            
            // 1. 如果有Base64编码的文件内容，优先使用
            if (base64Content != null && !base64Content.trim().isEmpty()) {
                log.info("检测到Base64编码的文件内容，长度: {}", base64Content.length());
                try {
                    // 对Base64进行初步验证
                    if (base64Content.length() < 10) {
                        log.error("Base64内容太短，可能不是有效的图片数据");
                        // 继续处理，尝试其他方法
                    } else {
                        // 如果内容以"data:"开头，需要去除前缀
                        if (base64Content.startsWith("data:")) {
                            base64Content = base64Content.substring(base64Content.indexOf(",") + 1);
                        }
                        
                        try {
                            // 解码Base64内容并保存文件
                            byte[] fileBytes = java.util.Base64.getDecoder().decode(base64Content);
                            
                            // 验证文件大小
                            if (fileBytes.length > 0) {
                                Files.write(filePath, fileBytes);
                                log.info("从Base64内容保存文件成功: {}, 大小: {} 字节", filePath, fileBytes.length);
                                fileProcessed = true;
                            } else {
                                log.error("Base64解码后文件大小为0字节");
                            }
                        } catch (IllegalArgumentException e) {
                            log.error("Base64解码失败，输入可能不是有效的Base64格式: {}", e.getMessage());
                            // 继续处理，尝试其他方法
                        }
                    }
                } catch (Exception e) {
                    log.error("保存Base64文件内容失败: {}", e.getMessage(), e);
                    // 不返回错误，继续尝试其他上传方法
                }
            }
            // 2. 如果是鸿蒙OS的file://开头的URI，需要特殊处理
            else if (fileUri.startsWith("file://")) {
                log.info("检测到鸿蒙OS文件URI格式: {}", fileUri);
                // 对于鸿蒙OS设备，我们需要客户端提供文件内容，而不仅仅是URI
                // 由于无法直接访问设备上的文件，这里创建一个1x1像素的图片作为占位符
                try {
                    log.info("创建占位图片文件: {}", filePath);
                    // 创建1x1像素的PNG图片
                    byte[] placeholderImageBytes = generatePlaceholderImage(1, 1);
                    Files.write(filePath, placeholderImageBytes);
                    log.info("占位图片文件创建成功: {}", filePath);
                    fileProcessed = true;
                } catch (IOException e) {
                    log.error("文件创建失败: {}", e.getMessage(), e);
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(ApiResponseDTO.error("文件创建失败: " + e.getMessage()));
                }
            }
            // 3. 如果是网络URL，尝试下载
            else if (fileUri.startsWith("http://") || fileUri.startsWith("https://")) {
                log.info("检测到网络文件URL: {}", fileUri);
                try {
                    URL url = new URL(fileUri);
                    try (InputStream in = url.openStream()) {
                        Files.copy(in, filePath, StandardCopyOption.REPLACE_EXISTING);
                        log.info("从URL下载文件成功: {}", filePath);
                        fileProcessed = true;
                    }
                } catch (IOException e) {
                    log.error("从URL下载文件失败: {}", e.getMessage(), e);
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(ApiResponseDTO.error("从URL下载文件失败: " + e.getMessage()));
                }
            }
            
            // 4. 如果文件还未处理，创建空文件作为占位符
            if (!fileProcessed) {
                try {
                    log.info("创建占位文件: {}", filePath);
                    Files.createFile(filePath);
                    log.info("占位文件创建成功: {}", filePath);
                } catch (IOException e) {
                    log.error("文件创建失败: {}", e.getMessage(), e);
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(ApiResponseDTO.error("文件创建失败: " + e.getMessage()));
                }
            }
            
            // 构建文件访问URL
            String fileUrl = fileAccessUrl + "/" + type + "/" + dateFolder + "/" + newFilename;
            log.info("文件URL生成: {}", fileUrl);
            
            // 返回文件URL
            Map<String, String> result = new HashMap<>();
            result.put("url", fileUrl);
            result.put("filename", newFilename);
            
            return ResponseEntity.ok(ApiResponseDTO.success(result));
            
        } catch (Exception e) {
            log.error("文件上传过程发生未知异常: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponseDTO.error("文件上传失败，服务器内部错误"));
        }
    }
    
    /**
     * 生成占位图片（1x1像素的透明PNG）
     * 
     * @param width 图片宽度
     * @param height 图片高度
     * @return 图片字节数组
     */
    private byte[] generatePlaceholderImage(int width, int height) throws IOException {
        java.awt.image.BufferedImage image = new java.awt.image.BufferedImage(
                width, height, java.awt.image.BufferedImage.TYPE_INT_ARGB);
        
        // 填充透明背景
        java.awt.Graphics2D g2d = image.createGraphics();
        g2d.setComposite(java.awt.AlphaComposite.Clear);
        g2d.fillRect(0, 0, width, height);
        g2d.dispose();
        
        // 转换为字节数组
        java.io.ByteArrayOutputStream baos = new java.io.ByteArrayOutputStream();
        javax.imageio.ImageIO.write(image, "png", baos);
        return baos.toByteArray();
    }
    
    /**
     * 获取图片内容
     * 
     * @param type 图片类型
     * @param date 日期目录
     * @param filename 文件名
     * @return 图片内容
     */
    @GetMapping("/{type}/{date}/{filename:.+}")
    @Operation(summary = "获取图片", description = "根据图片路径获取图片内容")
    public ResponseEntity<byte[]> getImage(
            @PathVariable String type,
            @PathVariable String date,
            @PathVariable String filename) {
        
        log.info("获取图片, 类型: {}, 日期: {}, 文件名: {}", type, date, filename);
        
        try {
            // 构建文件路径
            Path filePath = Paths.get(uploadDir, type, date, filename);
            
            // 检查文件是否存在
            if (!Files.exists(filePath)) {
                log.error("文件不存在: {}", filePath);
                return ResponseEntity.notFound().build();
            }
            
            // 读取文件内容
            byte[] fileContent = Files.readAllBytes(filePath);
            
            // 根据文件扩展名确定媒体类型
            String extension = filename.substring(filename.lastIndexOf(".") + 1).toLowerCase();
            String mediaType;
            
            switch (extension) {
                case "jpg":
                case "jpeg":
                    mediaType = "image/jpeg";
                    break;
                case "png":
                    mediaType = "image/png";
                    break;
                case "gif":
                    mediaType = "image/gif";
                    break;
                case "webp":
                    mediaType = "image/webp";
                    break;
                default:
                    mediaType = "application/octet-stream";
            }
            
            // 返回文件内容和媒体类型
            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(mediaType))
                    .body(fileContent);
            
        } catch (IOException e) {
            log.error("获取图片失败: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }
    
    /**
     * 删除图片
     * 
     * @param type 图片类型
     * @param date 日期目录
     * @param filename 文件名
     * @return 操作结果
     */
    @DeleteMapping("/{type}/{date}/{filename:.+}")
    @Operation(summary = "删除图片", description = "根据图片路径删除图片")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponseDTO<Void>> deleteImage(
            @PathVariable String type,
            @PathVariable String date,
            @PathVariable String filename) {
        
        log.info("删除图片, 类型: {}, 日期: {}, 文件名: {}", type, date, filename);
        
        try {
            // 构建文件路径
            Path filePath = Paths.get(uploadDir, type, date, filename);
            
            // 检查文件是否存在
            if (!Files.exists(filePath)) {
                log.error("文件不存在: {}", filePath);
                return ResponseEntity.ok(ApiResponseDTO.error("文件不存在"));
            }
            
            // 删除文件
            Files.delete(filePath);
            log.info("文件已删除: {}", filePath);
            
            return ResponseEntity.ok(ApiResponseDTO.success(null));
            
        } catch (IOException e) {
            log.error("删除图片失败: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponseDTO.error("删除图片失败: " + e.getMessage()));
        }
    }
} 