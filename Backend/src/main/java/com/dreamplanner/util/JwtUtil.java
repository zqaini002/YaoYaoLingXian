package com.dreamplanner.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

/**
 * JWT工具类，用于生成和验证JWT令牌
 */
@Component
public class JwtUtil {

    @Value("${jwt.secret:dreamPlannerSecretKey12345678901234567890}")
    private String secret;

    @Value("${jwt.expiration:86400000}")
    private long expiration; // 默认24小时

    /**
     * 从令牌中获取用户名
     *
     * @param token 令牌
     * @return 用户名
     */
    public String getUsernameFromToken(String token) {
        return getClaimFromToken(token, Claims::getSubject);
    }

    /**
     * 从令牌中获取过期时间
     *
     * @param token 令牌
     * @return 过期时间
     */
    public Date getExpirationDateFromToken(String token) {
        return getClaimFromToken(token, Claims::getExpiration);
    }

    /**
     * 从令牌中获取指定的声明
     *
     * @param token          令牌
     * @param claimsResolver 声明解析器
     * @return 声明
     */
    public <T> T getClaimFromToken(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = getAllClaimsFromToken(token);
        return claimsResolver.apply(claims);
    }

    /**
     * 从令牌中获取所有声明
     *
     * @param token 令牌
     * @return 所有声明
     */
    private Claims getAllClaimsFromToken(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .setAllowedClockSkewSeconds(300) // 允许5分钟的时钟偏差
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    /**
     * 检查令牌是否过期
     *
     * @param token 令牌
     * @return 是否过期
     */
    private Boolean isTokenExpired(String token) {
        final Date expiration = getExpirationDateFromToken(token);
        return expiration.before(new Date());
    }

    /**
     * 生成令牌
     *
     * @param userId   用户ID
     * @param username 用户名
     * @return 令牌
     */
    public String generateToken(Long userId, String username) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", userId);
        return doGenerateToken(claims, username);
    }

    /**
     * 生成令牌
     *
     * @param claims   声明
     * @param subject 主题（通常是用户名）
     * @return 令牌
     */
    private String doGenerateToken(Map<String, Object> claims, String subject) {
        final Date createdDate = new Date();
        final Date expirationDate = new Date(createdDate.getTime() + expiration);

        return Jwts.builder()
                .setClaims(claims)
                .setSubject(subject)
                .setIssuedAt(createdDate)
                .setExpiration(expirationDate)
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    /**
     * 验证令牌
     *
     * @param token    令牌
     * @param username 用户名
     * @return 是否有效
     */
    public Boolean validateToken(String token, String username) {
        final String tokenUsername = getUsernameFromToken(token);
        return (tokenUsername.equals(username) && !isTokenExpired(token));
    }

    /**
     * 获取签名密钥
     *
     * @return 签名密钥
     */
    private Key getSigningKey() {
        // 先尝试使用配置中的secret
        byte[] keyBytes = secret.getBytes();

        // 确保密钥足够长，如果不够，使用HS256算法自动生成
        if (keyBytes.length * 8 < 256) { // HS256需要至少256位
            return Keys.secretKeyFor(SignatureAlgorithm.HS256);
        }

        return Keys.hmacShaKeyFor(keyBytes);
    }
} 