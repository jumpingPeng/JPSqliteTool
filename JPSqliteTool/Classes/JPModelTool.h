//
//  ViewController.h
//  JPSqliteTool
//
//  Created by JUMPING on 2016/12/27.
//  Copyright © 2017年 JUMPING. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JPModelTool : NSObject


/**
 根据类名, 获取表格名称

 @param cls 类名
 @return 表格名称
 */
+ (NSString *)tableName:(Class)cls;

/**
 根据类名, 获取临时表格名称

 @param cls 类名
 @return 临时表格名称
 */
+ (NSString *)tmpTableName:(Class)cls;


/**
 所有的有效成员变量, 以及成员变量对应的类型

 @param cls 类名
 @return 所有的有效成员变量, 以及成员变量对应的类型
 */
+ (NSDictionary *)classIvarNameTypeDic:(Class)cls;


/**
 所有的成员变量, 以及成员变量映射到数据库里面对应的类型

 @param cls 类名
 @return 所有的成员变量, 以及成员变量映射到数据库里面对应的类型
 */
+ (NSDictionary *)classIvarNameSqliteTypeDic:(Class)cls;


/**
 字段名称和sql类型, 拼接的用户创建表格的字符串

 @param cls 类名
 @return 字符串 如: name text,age integer,score real
 */
+ (NSString *)columnNamesAndTypesStr:(Class)cls;


/**
 排序后的类名对应的成员变量数组, 用于和表格字段进行验证是否需要更新

 @param cls 类名
 @return 成员变量数组,
 */
+ (NSArray *)allTableSortedIvarNames:(Class)cls;

@end
