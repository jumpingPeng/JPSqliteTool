//
//  ViewController.h
//  JPSqliteTool
//
//  Created by JUMPING on 2016/12/27.
//  Copyright © 2017年 JUMPING. All rights reserved.
//

#import "JPTableTool.h"
#import "JPModelTool.h"
#import "JPSqliteTool.h"

@implementation JPTableTool

+ (NSArray *)tableSortedColumnNames:(Class)cls uid:(NSString *)uid {
    
    NSString *tableName = [JPModelTool tableName:cls];
    
    // CREATE TABLE JPStu(age integer,stuNum integer,score real,name text, primary key(stuNum))
    
    NSString *queryCreateSqlStr = [NSString stringWithFormat:@"select sql from sqlite_master where type = 'table' and name = '%@'", tableName];
    
    
    NSMutableDictionary *dic = [JPSqliteTool querySql:queryCreateSqlStr uid:uid].firstObject;
    
    NSString *createTableSql = dic[@"sql"];
    if (createTableSql.length == 0) {
        return nil;
    }
    createTableSql = [createTableSql stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
    

    
    createTableSql = [createTableSql stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    createTableSql = [createTableSql stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    createTableSql = [createTableSql stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    
       
    
    NSString *nameTypeStr = [createTableSql componentsSeparatedByString:@"("][1];
    
    // age integer
    // stuNum integer
    // score real
    // name text
    // primary key
    NSArray *nameTypeArray = [nameTypeStr componentsSeparatedByString:@","];
    
    NSMutableArray *names = [NSMutableArray array];
    for (NSString *nameType in nameTypeArray) {
        
        if ([[nameType lowercaseString] containsString:@"primary"]) {
            continue;
        }
        NSString *nameType2 = [nameType stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        
        
        // age integer
        NSString *name = [nameType2 componentsSeparatedByString:@" "].firstObject;
        
        [names addObject:name];
        
        
    }
    
    
    [names sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    return names;
}

+ (BOOL)isTableExists:(Class)cls uid:(NSString *)uid {
    
    NSString *tableName = [JPModelTool tableName:cls];
    NSString *queryCreateSqlStr = [NSString stringWithFormat:@"select sql from sqlite_master where type = 'table' and name = '%@'", tableName];
    
    NSMutableArray *result = [JPSqliteTool querySql:queryCreateSqlStr uid:uid];
    
    return result.count > 0;
}

@end
