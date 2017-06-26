//
//  ViewController.h
//  JPSqliteTool
//
//  Created by JUMPING on 2016/12/27.
//  Copyright © 2017年 JUMPING. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JPModelProtocol.h"


typedef NS_ENUM(NSUInteger, ColumnNameToValueRelationType) {
    ColumnNameToValueRelationTypeMore,
    ColumnNameToValueRelationTypeLess,
    ColumnNameToValueRelationTypeEqual,
    ColumnNameToValueRelationTypeMoreEqual,
    ColumnNameToValueRelationTypeLessEqual,
};


@interface JPSqliteModelTool : NSObject


/**
 根据一个模型类, 创建数据库表

 @param cls 类名
 @param uid 用户唯一标识
 @return 是否创建成功
 */
+ (BOOL)createTable:(Class)cls uid:(NSString *)uid;


/**
 判断一个表格是否需要更新

 @param cls 类名
 @param uid 用户唯一标识
 @return 是否需要更新
 */
+ (BOOL)isTableRequiredUpdate:(Class)cls uid:(NSString *)uid;


/**
 更新表格

 @param cls 类名
 @param uid 用户唯一标识
 @return 是否更新成功
 */
+ (BOOL)updateTable:(Class)cls uid:(NSString *)uid;


+ (BOOL)saveOrUpdateModel:(id)model uid:(NSString *)uid;


+ (BOOL)deleteModel:(id)model uid:(NSString *)uid;

// 根据条件来删除
// age > 19
// score <= 10 and xxx
+ (BOOL)deleteModel:(Class)cls whereStr:(NSString *)whereStr uid:(NSString *)uid;

// score > 10 or name = 'xx'
+ (BOOL)deleteModel:(Class)cls columnName:(NSString *)name relation:(ColumnNameToValueRelationType)relation value:(id)value uid:(NSString *)uid;

// sql
//+ (BOOL)deleteWithSql:(NSString *)sql uid:(NSString *)uid;

// @[@"score", @"name"] @[@">", @"="] @[@"10", @"xx"]
//+ (BOOL)deleteModels:(Class)cls columnNames:(NSArray *)names relations:(NSArray *)relations values:(NSArray *)values naos:(NSArray *)naos uid:(NSArray *)uid;


+ (NSArray *)queryAllModels:(Class)cls uid:(NSString *)uid;
+ (NSArray *)queryModels:(Class)cls columnName:(NSString *)name relation:(ColumnNameToValueRelationType)relation value:(id)value uid:(NSString *)uid;

+ (NSArray *)queryModels:(Class)cls WithSql:(NSString *)sql uid:(NSString *)uid;


@end
