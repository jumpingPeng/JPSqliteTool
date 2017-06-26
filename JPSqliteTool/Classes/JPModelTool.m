//
//  ViewController.h
//  JPSqliteTool
//
//  Created by JUMPING on 2016/12/27.
//  Copyright © 2017年 JUMPING. All rights reserved.
//

#import "JPModelTool.h"
#import "JPModelProtocol.h"
#import <objc/runtime.h>

@implementation JPModelTool

/**
 根据类名, 获取表格名称

 @param cls 类名
 @return 表格名称
 */
+ (NSString *)tableName:(Class)cls {
    return NSStringFromClass(cls);
}

/**
 根据类名, 获取临时表格名称

 @param cls 类名
 @return 临时表格名称
 */
+ (NSString *)tmpTableName:(Class)cls {
    return [NSStringFromClass(cls) stringByAppendingString:@"_tmp"];
}


/**
 所有的有效成员变量, 以及成员变量对应的类型
 // 有效的成员变量名称, 以及, 对应的类型
 @param cls 类名
 @return 所有的有效成员变量, 以及成员变量对应的类型
 */
+ (NSDictionary *)classIvarNameTypeDic:(Class)cls {
    
    // 获取这个类, 里面, 所有的成员变量以及类型
    
    unsigned int outCount = 0;
    Ivar *varList = class_copyIvarList(cls, &outCount);
    
    NSMutableDictionary *nameTypeDic = [NSMutableDictionary dictionary];
    
    NSArray *ignoreNames = nil;
    if ([cls respondsToSelector:@selector(ignoreColumnNames)]) {
        ignoreNames = [cls ignoreColumnNames];
    }
    
    
    
    for (int i = 0; i < outCount; i++) {
        Ivar ivar = varList[i];
        
        // 1. 获取成员变量名称
        NSString *ivarName = [NSString stringWithUTF8String: ivar_getName(ivar)];
        if ([ivarName hasPrefix:@"_"]) {
            ivarName = [ivarName substringFromIndex:1];
        }
        
        
        if([ignoreNames containsObject:ivarName]) {
            continue;
        }
        
        // 2. 获取成员变量类型
        NSString *type = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
        
        type = [type stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@\""]];
        
        
        [nameTypeDic setValue:type forKey:ivarName];
    }
    
    return nameTypeDic;
    
}

/**
 所有的成员变量, 以及成员变量映射到数据库里面对应的类型

 @param cls 类名
 @return 所有的成员变量, 以及成员变量映射到数据库里面对应的类型
 */
+ (NSDictionary *)classIvarNameSqliteTypeDic:(Class)cls {
    
    NSMutableDictionary *dic = [[self classIvarNameTypeDic:cls] mutableCopy];
    
    NSDictionary *typeDic = [self ocTypeToSqliteTypeDic];
    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {
        dic[key] = typeDic[obj];
    }];
    
    return dic;
    
}

/**
 字段名称和sql类型, 拼接的用户创建表格的字符串

 @param cls 类名
 @return 字符串 如: name text,age integer,score real
 */
+ (NSString *)columnNamesAndTypesStr:(Class)cls {
    
    NSDictionary *nameTypeDic = [self classIvarNameSqliteTypeDic:cls];
//    {
//        age = integer;
//        b = integer;
//        name = text;
//        score = real;
//        stuNum = integer;
//    }
    
//    age integer,b integer
    
    NSMutableArray *result = [NSMutableArray array];
    [nameTypeDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL * _Nonnull stop) {

        [result addObject:[NSString stringWithFormat:@"%@ %@", key, obj]];
    }];
    
    
   return [result componentsJoinedByString:@","];
    
}

/**
 排序后的类名对应的成员变量数组, 用于和表格字段进行验证是否需要更新

 @param cls 类名
 @return 成员变量数组,
 */
+ (NSArray *)allTableSortedIvarNames:(Class)cls {
    
    NSDictionary *dic = [self classIvarNameTypeDic:cls];
    NSArray *keys = dic.allKeys;
    keys = [keys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    return keys;
}


#pragma mark - 私有的方法
+ (NSDictionary *)ocTypeToSqliteTypeDic {
    return @{
             @"d": @"real", // double
             @"f": @"real", // float
             
             @"i": @"integer",  // int
             @"q": @"integer", // long
             @"Q": @"integer", // long long
             @"B": @"integer", // bool
             
             @"NSData": @"blob",
             @"NSDictionary": @"text",
             @"NSMutableDictionary": @"text",
             @"NSArray": @"text",
             @"NSMutableArray": @"text",
             
             @"NSString": @"text"
             };

}



@end
