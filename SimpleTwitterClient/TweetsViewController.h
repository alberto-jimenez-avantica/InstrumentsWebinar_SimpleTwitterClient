//
//  TweetsViewController.h
//  SimpleTwitterClient
//
//  Created by Alberto Jimenez on 7/1/13.
//  Copyright (c) 2013 Avantica Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 * Como se vio en el webinar, se tienen dos posibles soluciones a la hora de obtener las
 * imágenes de cada uno de los tweets, la primera, una forma menos eficiente, en la que
 * se descarga todas las imágenes de todos los tweets cada vez que se va mostrar la celda,
 * incluso cuando se hace scroll en la tabla. Además, en esta primera solución se descargan
 * las imágenes en el hilo principal, algo que NUNCA se debe hacer para evitar que la
 * interfaz de usuario deje de responder a interacciones.
 *
 * La segunda solución, utilizaba un cache para evitar la descarga de las imágenes múltiples
 * veces, además realiza esta descarga en un hilo secundario.
 *
 * Para ejecutar la primera solución, comentar la línea #define OPTIMIZED_SOLUTION, lo que
 * evitará que se compile el código optimizado
 */

#define OPTIMIZED_SOLUTION

@interface TweetsViewController : UITableViewController

@end
