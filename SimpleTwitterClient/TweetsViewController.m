//
//  TweetsViewController.m
//  SimpleTwitterClient
//
//  Created by Alberto Jimenez on 7/1/13.
//  Copyright (c) 2013 Avantica Technologies. All rights reserved.
//

#import "TweetsViewController.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>

/*
 * En este archivo, todo código que está entre #ifdef OPTIMIZED_SOLUTION y su
 * respectivo #endif se utiliza solo para la solución optimizada, y no se
 * compila si se comenta la línea #define OPTIMIZED_SOLUTION en TweetsViewController.h
 */

@interface TweetsViewController ()

@property (nonatomic, strong) NSArray *tweets;
#ifdef OPTIMIZED_SOLUTION
// Variable para mantener el cache de las imágenes,
// utiliza el URL de la imágen como llave y la imagen como valor
@property (atomic, strong) NSCache *imagesCache;
// Diccionario para almacenar cuales imágenes se están descargando
// y cuales celdas se deben refrescar al terminar la descarga
@property (atomic, strong) NSMutableDictionary *imagesDownloading;
#endif

@end

@implementation TweetsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Inicialización de variables de instancia
    self.tweets = [NSArray array];
#ifdef OPTIMIZED_SOLUTION
    self.imagesCache = [[NSCache alloc] init];
    self.imagesDownloading = [[NSMutableDictionary alloc] init];
#endif
    
    // Llamada para obtener el JSON desde Twitter con los tweets
    // y guardarlos en self.tweets
    [self getTweets];
}

#pragma mark Twitter Methods
// Método que indica si el usuario tiene acceso a Twitter.
// Utiliza la clase SLComposeViewController que está disponible
// solo para iOS 6 o superior
- (BOOL)userHasAccessToTwitter
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

// Método para obtener los tweets
- (void)getTweets
{
    // Pregunta si el usuario tiene acceso a Twitter
    if ([self userHasAccessToTwitter]) {
        // Crea un ACAccountStore y un ACAccountType para Twitter
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *twitterAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [accountStore requestAccessToAccountsWithType:twitterAccountType options:nil completion:^(BOOL granted, NSError *error) {
            // Si el usuario dio permiso para utilizar la cuenta de Twitter
            if (granted) {
                // Obtiene las diferentes cuentas configuradas
                NSArray *twitterAccounts = [accountStore accountsWithAccountType:twitterAccountType];
                // URL para obtener el home timeline de la cuenta seleccionada
                NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
                // Se van a solicitar los 200 tweets más recientes
                NSDictionary *params = @{@"count" : @"200"};
                // Se crea el SLRequest de tipo Twitter, va a ser un GET, al URL url y con los parámetros params
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:url parameters:params];
                // Para obtener el home timeline se debe estár autenticado, por lo que se settea una cuenta de Twitter
                [request setAccount:[twitterAccounts lastObject]];
                
                // Realiza el request y ejecuta el bloque de código dado al finalizar
                [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    // Si la respuesta contiene datos
                    if (responseData) {
                        // Si el código de respuesta fue 2xx
                        if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300) {
                            NSError *jsonError;
                            // Parsea el JSON y lo almacena en un Array
                            NSArray *timelineData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&jsonError];
                            
                            // Si el parseo fue exitoso
                            if (timelineData) {
                                // Almacena los tweets en self.tweets
                                self.tweets = timelineData;
                                // Recarga la tabla para que aparezcan los tweets recién descargados
                                // Al ser una operación de UI la ejecutamos en el hilo principal utilizando
                                // performSelectorOnMainThread:withObject:waitUntilDone:
                                [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
                            }
                            else { // Error en el parseo
                                NSLog(@"Error al parsear el JSON: %@", [jsonError localizedDescription]);
                            }
                        }
                        else { // Código de respuesta distinto de 2xx
                            NSLog(@"Código de respuesta: %d", urlResponse.statusCode);
                        }
                    }
                }];
            }
            else { // El usuario no le dio los permisos requeridos de la cuenta de Twitter
                NSLog(@"Error al solicitar permisos al usuario: %@", [error localizedDescription]);
            }
        }];
    }
    else { // Usuario sin acceso a Twitter
        NSLog(@"El usuario no tiene acceso a Twitter");
        NSLog(@"### Configurar en Settings una cuenta de Twitter válida ###");
    }
}

#pragma mark UITableView Methods
// Método del delegate opcional en el protocolo UITableViewDelegate
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Devuelve 80.0 como la altura de todas las celdas para mostrar dos líneas del tweet
    return 80.0;
}

// Método obligatorio del protocolo UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // La cantidad de celdas a mostrar va a ser igual a la cantidad de elementos en el
    // arreglo self.tweets
    return [self.tweets count];
}

// Método obligatorio del protocolo UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reusableIdentifier = @"TweetCell";
    
    // Solicitamos una celda reutilizable al tableView con un identificador TweetCell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableIdentifier];
    
    // Si no hay celdas reutilizables inicializamos una nueva con estilo subtítulo
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reusableIdentifier];
    }
    
    // Obtiene el tweet correspondiente a la fila solicitada
    NSDictionary *tweet = [self.tweets objectAtIndex:indexPath.row];
    // Obtiene la información del usuario
    NSDictionary *user = [tweet objectForKey:@"user"];
    
    // Obtenemos el nombre del usuario de la información en user
    // y lo ponemos en el label del título de la celda
    cell.textLabel.text = [user objectForKey:@"screen_name"];
    // Obtenemos el texto del tweet y lo ponemos en el label
    // del subtítulo
    cell.detailTextLabel.text = [tweet objectForKey:@"text"];
    // Asignamos nil a la imagen en la celda para evitar imágenes
    // anteriores de mantenerse en la celda que no corresponde
    cell.imageView.image = nil;
    // Obtiene el URL de la imagen de perfil del usuario
    NSURL *imageURL = [NSURL URLWithString:[user objectForKey:@"profile_image_url"]];
    
#ifdef OPTIMIZED_SOLUTION
    // Pide la imagen al cache
    UIImage *image = [self.imagesCache objectForKey:imageURL];
    
    // Si existe actualiza la imagen de la celda con la del cache
    if (image) {
        cell.imageView.image = image;
    }
    else { // Si no existe manda a descargar la imagen
        [self getImageFromURL:imageURL forCellAtIndexPath:indexPath];
    }
#else
    // Descarga la imagen utilizando dataWithContentsOfURL: (NUNCA utilizar este método
    // en el hilo principal), y se la asigna a la imagen de la celda
    cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
#endif
    
    // Retorna la celda ya configurada
    return cell;
}

#pragma mark Utility Methods
#ifdef OPTIMIZED_SOLUTION
// Método para obtener la imagen de perfil en un hilo secundario y
// actualizando las celdas correspondientes
- (void)getImageFromURL:(NSURL *)url forCellAtIndexPath:(NSIndexPath *)indexPath
{
    // Obtiene el arreglo con los indices a actualizar
    NSMutableArray *indexPathsToUpdate = [self.imagesDownloading objectForKey:url];
    
    // Si no existe, entonces es porque la imagen no se ha empezado a descargar
    if (!indexPathsToUpdate) {
        // Se crea un NSMutableArray para albergar los indexPaths por actualizar
        indexPathsToUpdate = [[NSMutableArray alloc] initWithObjects:indexPath, nil];
        // Se agrega ese arreglo al diccionario self.imagesDownloading
        [self.imagesDownloading setObject:indexPathsToUpdate forKey:url];
        
        // Se crea un hilo con prioridad background y se manda a
        // descargar la imagen a ese hilo
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            // Se obtiene la imagen utilizando dataWithContentsOfURL:
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
            // Se actualiza el cache
            [self.imagesCache setObject:image forKey:url];
            // Se obtienen los índices a actualizar, no se utilizan los mismos porque
            // dataWithContentsOfURL: puede tomar mucho tiempo en concluir y pueden
            // haber nuevos índices que deben ser actualizados
            NSArray *toUpdate = [self.imagesDownloading objectForKey:url];
            // Se actualizan las celdas requeridas pero se debe realizar en el hilo
            // principal para evitar un delay en la actualización del UI
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadRowsAtIndexPaths:toUpdate withRowAnimation:UITableViewRowAnimationNone];
            });
            // Se elimina el url de self.imagesDownloading
            [self.imagesDownloading removeObjectForKey:url];
        });
    }
    else {
        // Si ya existe, quiere decir que ya se está descargando y debemos
        // solo agregar el indexPath para que se actualice esta celda
        [indexPathsToUpdate addObject:indexPath];
    }
}
#endif

@end
