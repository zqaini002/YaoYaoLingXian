package com.dreamplanner.controller;

import com.dreamplanner.dto.ApiResponseDTO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

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
     * 上传图片接口
     *
     * @param file 图片文件
     * @param type 图片类型（dream、task、progress、avatar等）
     * @return 图片URL
     */
    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "上传图片", description = "上传图片文件并返回访问URL")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponseDTO<Map<String, String>>> uploadImage(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "type", defaultValue = "common") String type) {
        
        log.info("开始上传图片, 类型: {}, 大小: {} bytes", type, file.getSize());
        
        try {
            // 检查文件是否为空
            if (file.isEmpty()) {
                log.error("上传失败，文件为空");
                return ResponseEntity.badRequest()
                        .body(ApiResponseDTO.error("上传失败，文件为空"));
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
            }
            String newFilename = UUID.randomUUID().toString() + fileExtension;
            
            // 保存文件
            Path filePath = targetPath.resolve(newFilename);
            Files.copy(file.getInputStream(), filePath);
            
            // 构建文件访问URL
            String fileUrl = fileAccessUrl + "/" + type + "/" + dateFolder + "/" + newFilename;
            log.info("文件保存成功, 路径: {}, URL: {}", filePath, fileUrl);
            
            // 返回文件URL
            Map<String, String> result = new HashMap<>();
            result.put("url", fileUrl);
            result.put("filename", newFilename);
            
            return ResponseEntity.ok(ApiResponseDTO.success(result));
            
        } catch (IOException e) {
            log.error("文件上传失败: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponseDTO.error("文件上传失败: " + e.getMessage()));
        }
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