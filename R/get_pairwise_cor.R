get_pairwise_cor <-
function(Xome_data,Yome_data,max_xvar=100,max_yvar=100,rsd.filt.thresh=3,corthresh=0.4,keepX=100,keepY=100,pairedanalysis=FALSE,optselect=TRUE,classlabels=NA,rawPthresh=0.05,plsmode="regression",xmwasmethod="pls",numcomps=10,net_edge_colors=c("blue","red"),net_node_colors=c("orange", "green"),outloc=NA,Xname="X",Yname="Y",num_nodes=2,net_node_shape=c("rectangle", "circle"),seednum=100,tempXname="X",tempYname="Y"){


filename<-paste(Xname,Yname,sep="_x_")

print(paste("Performing ",filename," integrative analysis",sep=""))


numsampX<-dim(Xome_data)[2]

cor_thresh_check=seq(corthresh,1,0.01)

min_cor_thresh=0.9

cor_thresh_check=rev(cor_thresh_check)



for(c in cor_thresh_check){
    
    p1=corPvalueStudent(cor=c,n=numsampX)
    if(p1<rawPthresh){
        
        min_cor_thresh=c
    }
}

if(corthresh<min_cor_thresh){
    
    corthresh=min_cor_thresh
}

cl<-makeSOCKcluster(num_nodes)
clusterExport(cl,"do_rsd")


feat_rsds<-parApply(cl,Xome_data,1,do_rsd)
			
stopCluster(cl)

abs_feat_rsds<-abs(feat_rsds)

if(is.na(max_xvar)==FALSE){

if(dim(Xome_data)[1]>max_xvar){

Xome_data<-Xome_data[order(abs_feat_rsds,decreasing=TRUE)[1:max_xvar],]

abs_feat_rsds<-abs_feat_rsds[order(abs_feat_rsds,decreasing=TRUE)[1:max_xvar]]

}

}


	
good_metabs<-which(abs_feat_rsds>rsd.filt.thresh)

Xome_data<-Xome_data[good_metabs,]


cl<-makeSOCKcluster(num_nodes)

clusterExport(cl,"do_rsd")
feat_rsds<-parApply(cl,Yome_data,1,do_rsd)
			
stopCluster(cl)

abs_feat_rsds<-abs(feat_rsds)

if(is.na(max_yvar)==FALSE){
if(dim(Yome_data)[1]>max_yvar){

Yome_data<-Yome_data[order(abs_feat_rsds,decreasing=TRUE)[1:max_yvar],]

abs_feat_rsds<-abs_feat_rsds[order(abs_feat_rsds,decreasing=TRUE)[1:max_yvar]]
}
}
					
good_metabs<-which(abs_feat_rsds>rsd.filt.thresh)
					
Yome_data<-Yome_data[good_metabs,]

if(nrow(Xome_data)<1){
    
    stop("None of the X variables meet the rsd threshold in the pairwise analysis.")
}

if(nrow(Yome_data)<1){
    
    stop("None of the Y variables meet the rsd threshold in the pairwise analysis.")
}


setwd(outloc)

X=Xome_data
Y=Yome_data


X<-as.data.frame(X)
Y<-as.data.frame(Y)


numsampX<-dim(X)[2]

numsampY<-dim(Y)[2]


if(numsampX!=numsampY){

	stop("Number of samples do not match between X and Y matrices.")
}





metabname_1<-rownames(Xome_data) #paste(Xome_data[,1],sep="_")
microbname_1<-rownames(Yome_data) #Yome_data[,1]

metabname<-paste(tempXname,seq(1,dim(Xome_data)[1]),sep="")
microbname<-paste(tempYname,seq(1,dim(Yome_data)[1]),sep="")

id_mapping_mat1<-cbind(metabname_1,metabname)
id_mapping_mat2<-cbind(microbname_1,microbname)

id_mapping_mat<-rbind(id_mapping_mat1,id_mapping_mat2)

id_mapping_mat<-as.data.frame(id_mapping_mat)

colnames(id_mapping_mat)<-c("Name","Node")

if(is.na(keepX)==TRUE){
    
    keepX<-dim(X)[1]
}

if(is.na(keepY)==TRUE){
    
    keepY<-dim(Y)[1]
}

if(keepX>dim(X)[1]){
	keepX<-dim(X)[1]
}

if(keepY>dim(Y)[1]){
	keepY<-dim(Y)[1]
}


X<-t(X)
Y<-t(Y)


if(FALSE){
save(id_mapping_mat1,file="id_mapping_mat1.Rda")
save(id_mapping_mat2,file="id_mapping_mat2.Rda")
save(id_mapping_mat,file="id_mapping_mat.Rda")
save(X,file="X.Rda")
save(Y,file="Y.Rda")
}

#numcomps<-pls.regression.cv(Xtrain=X,Ytrain=Y,ncomp=numcomps,alpha=2/3)

colnames(X)<-metabname
colnames(Y)<-microbname



if(xmwasmethod=="spls"){
linn.pls<-do_plsda(X=X,Y=Y,oscmode="spls",numcomp=numcomps,keepX=keepX,keepY=keepY,sparseselect=TRUE,analysismode=plsmode,pairedanalysis=pairedanalysis,optselect=optselect,design=classlabels)

}else{
    
    if(xmwasmethod=="pls"){
        linn.pls<-do_plsda(X=X,Y=Y,oscmode="pls",numcomp=numcomps,keepX=keepX,keepY=keepY,sparseselect=FALSE,analysismode=plsmode,pairedanalysis=pairedanalysis,optselect=optselect,design=classlabels)
    }else{
        
        
        if(xmwasmethod=="o1pls"){
            linn.pls<-do_plsda(X=X,Y=Y,oscmode="o1pls",numcomp=numcomps,keepX=keepX,keepY=keepY,sparseselect=FALSE,analysismode=plsmode,pairedanalysis=pairedanalysis,optselect=optselect,design=classlabels)
        }else{
            
            
            if(xmwasmethod=="o1spls"){
                linn.pls<-do_plsda(X=X,Y=Y,oscmode="o1pls",numcomp=numcomps,keepX=keepX,keepY=keepY,sparseselect=TRUE,analysismode=plsmode,pairedanalysis=pairedanalysis,optselect=optselect,design=classlabels)
            }
        }
    }
}



numcomps<-linn.pls$opt_comp
linn.pls<-linn.pls$model

print(paste("Number of optimal (s)PLS components: ",numcomps,sep=""))


#pdf("network_all.png")
png("network_all.png",width=8,height=8,res=600,type="cairo",units="in")

n1<-try(network(linn.pls, comp = 1:numcomps, threshold=0),silent=TRUE)

if(is(n1,"try-error")){
    
    n1<-try(network(linn.pls, comp = 1:numcomps, cutoff=0),silent=TRUE)
    
    if(is(n1,"try-error")){
     
        stop("Network analysis could not be performed. Please check the mixOmics version (<=6.1.3 required).")
    }

}

dev.off()
#save(n1,file="res1.Rda")
unlink("network_all.png")

x<-n1$M

#write.table(x,file="Int_allassociationscoresA.txt",sep="\t")


simmat_colnames<-colnames(x)

simmat_col_ind<-gsub(simmat_colnames,pattern=Yname,replacement="")

microbname_1_simmat<-microbname_1[as.numeric(as.character(simmat_col_ind))]

colnames(x)<-as.character(microbname_1_simmat)

rnames1<-rownames(x)

rnames_ind<-gsub(rnames1,pattern=Xname,replacement="")

rnames_ind<-as.numeric(as.character(rnames_ind))

rnames_ind2<-metabname_1[rnames_ind]

rownames(x)<-as.character(rnames_ind2)

fname1<-paste(Xname,"_x_",Yname,"_all_association_matrix.txt",sep="")
write.table(x,file=fname1,sep="\t")


maxcor<-apply(abs(x),1,max)
maxcor1<-apply(abs(x),2,max)


rnames<-rnames1 	#paste("X",seq(1,dim(x)[1]),sep="")
cnames<-simmat_colnames #paste("Y",seq(1,dim(x)[2]),sep="")


colnames(x)<-as.character(cnames)
rownames(x)<-as.character(rnames)


#microbname_1: original col names
#rnames_ind2: original row names
#simmat_colnames: Y labels
#rnames1: X labels



highcorsimMat<-x #[which(maxcor>=mincor),]



highcorsimMat[which(highcorsimMat>1)]<-1
highcorsimMat[which(highcorsimMat<(-1))]<-(-1)


x=as.matrix(x)

## 'threshold' is the limit to consider a link between to variable. Is directly changeable
## with interactive = TRUE



#for(corthresh in cor_thresh_list_all)

print_message<-paste("Generating global network plot at threshold: ",corthresh,sep="")
print(print_message)

set.seed(seednum)

print(corthresh)
print(numsampX)

p1=corPvalueStudent(cor=corthresh,n=numsampX)
	if(p1>rawPthresh){
		print(paste("correlation threshold ",corthresh," did not pass significance test.",sep=""))
	}else{

rownames(x)<-as.character(rnames1)
colnames(x)<-as.character(simmat_colnames)

highcorsimMat=x


if(corthresh>max(x)){
    print(paste("Max correlation is: ",max(x),sep=""))
    stop(paste("Please lower the correlation threshold.",sep=""))
    #break;
}

#if(outputformat=="tiff"){
#	fname<-paste(filename,"association_networkthreshold",corthresh,".tiff",sep="")
#	tiff(fname, width=5000,height=5000, res=600)
#}else{

	fname<-paste(filename,"_association_network_threshold",corthresh,".png",sep="")
    #pdf(fname)
    png(fname,width=8,height=8,res=600,type="cairo",units="in")
    

#}


par_rows=1
par(mfrow=c(par_rows,1))

net_result<-try(network(mat=as.matrix(highcorsimMat), threshold=corthresh,row.names = TRUE, col.names = TRUE, block.var.names = TRUE,color.node = net_node_colors,shape.node = net_node_shape,
        color.edge = net_edge_colors,lty.edge = "solid", lwd.edge = 1,show.edge.labels = FALSE, interactive = FALSE,cex.node.name=0.7,show.color.key = FALSE),silent=TRUE)
        
         if(is(net_result,"try-error")){
             
             
             net_result<-try(network(mat=as.matrix(highcorsimMat), cutoff=corthresh,row.names = TRUE, col.names = TRUE, block.var.names = TRUE,color.node = net_node_colors,shape.node = net_node_shape,
             color.edge = net_edge_colors,lty.edge = "solid", lwd.edge = 1,show.edge.labels = FALSE, interactive = FALSE,cex.node.name=0.7,show.color.key = FALSE),silent=TRUE)
    
                 if(is(net_result,"try-error")){
                  
                  net_result<-try(network(mat=as.matrix(highcorsimMat), threshold=corthresh,row.names = TRUE, col.names = TRUE, block.var.names = TRUE,color.node = net_node_colors,shape.node = net_node_shape,
                  color.edge = net_edge_colors,lty.edge = c("solid", "solid"), lwd.edge = c(1, 1),show.edge.labels = FALSE, interactive = FALSE,cex.node.name=0.7,show.color.key = FALSE),silent=TRUE)
                  
                  if(is(net_result,"try-error")){
                        stop("Network analysis could not be performed. Please check mixOmics version (<=6.1.3) required.")
                  }
                  
                  
                  
                 }
             
         }
         
         mtext("(Edges) Red: +ve correlation; Blue: -ve correlation",line=1,side=1,cex=0.8,adj=0)
         
         mtext_community<-paste("(Nodes) Rectangle: ",Xname,"; Circle: ",Yname,sep="")
         
         mtext(mtext_community,side=1,cex=0.8,line=2,adj=0)
         

         try(mtext(fname,line=3,cex=0.6,col="brown",side=1,adj=0),silent=TRUE)
         
         


dev.off()


rownames(x)<-as.character(rnames_ind2)
colnames(x)<-as.character(microbname_1_simmat)

fname<-paste(filename,"netresult",".Rda",sep="")

save(net_result,file=fname)
#cytoscape_fname<-paste(filename,"all_mzclusternetworkthreshold",corthresh,"_",numcomps,"pcs_cytoscape.gml",sep="")
#write.graph(net_result$gR, file =cytoscape_fname, format = "gml")

xtemp<-x[which(maxcor>=corthresh),which(maxcor1>=corthresh)]

xtemp<-cbind(rnames1[which(maxcor>=corthresh)],xtemp)
            xtemp1<-rbind(c("xName",simmat_colnames[which(maxcor1>=corthresh)]),xtemp)


#net_result$M<-cor2pcor(net_result$M)

fname<-paste(filename,"_association_matrix_threshold",corthresh,".txt",sep="")
write.table(xtemp1,file=fname,sep="\t")

xtemp<-abs(x[which(maxcor>=corthresh),which(maxcor1>=corthresh)])

xtemp[which(xtemp>=corthresh)]<-1
xtemp[which(xtemp<corthresh)]<-0

if(length(which(maxcor>=corthresh))>1){
NumConnections<-apply(xtemp,1,sum)
}else{
	NumConnections<-sum(xtemp)
}

xtemp<-cbind(rnames1[which(maxcor>=corthresh)],xtemp)
            xtemp1<-rbind(c("xName",simmat_colnames[which(maxcor1>=corthresh)]),xtemp)


rownames(x)<-as.character(rnames1)
colnames(x)<-as.character(simmat_colnames)



xtemp1<-cbind(xtemp,NumConnections)

fname<-paste(filename,"Boolean_association_matrix_threshold",corthresh,".txt",sep="")
write.table(xtemp1,file=fname,sep="\t")



#fname<-paste(filename,"association_matrix_corthresh",corthresh,"rowcollabels.txt",sep="")
#write.table(xtempA,file=fname,sep="\t")

if(nrow(net_result$M[which(maxcor>=corthresh),])<0){
	break
}
edge_matrix<-apply(net_result$M[which(maxcor>=corthresh),],1,function(x){which(abs(x)>corthresh)})

#if(length(ncol(edge_matrix))>0)

mat_cnames<-colnames(net_result$M)

col_A<-names(edge_matrix)

edge_matrix_1<-{}
for(r in 1:length(col_A)){
    
    #col_B<-names(edge_matrix[[r]])
    col_B<-mat_cnames[edge_matrix[[r]]]
    
   
    for(s in 1:length(col_B)){
    
    
    edge_matrix_1<-rbind(edge_matrix_1,cbind(col_A[r],col_B[s]))
    }
}

if(nrow(edge_matrix_1)<1){

	stop("No connections found.")
}

save(edge_matrix_1,file="edge_matrix_1.Rda")
    g1<-graph.data.frame(edge_matrix_1,directed=FALSE) #net_result$gR
    g2<-get.edgelist(g1)
    
    weight_vec<-{}
    for(rnum in 1:dim(g2)[1]){
        
        X_name<-which(rnames1==g2[rnum,1]) #as.numeric(as.character(gsub(g2[rnum,1],pattern=Xname,replacement="")))
        Y_name<-which(simmat_colnames==g2[rnum,2]) #as.numeric(as.character(gsub(g2[rnum,2],pattern=Yname,replacement="")))
        weight_vec<-c(weight_vec,net_result$M[X_name,Y_name])
        #weight_vec<-abs(weight_vec)
    }
    

    
    df<-data.frame(from=g2[,1],to=g2[,2],weight=weight_vec)
    
    rownames(x)<-as.character(rnames_ind2)
    colnames(x)<-as.character(microbname_1_simmat)
    
    

    }

	return(list(graphobject=df,rownames_vec=rnames1,colnames_vec=simmat_colnames,cormatrix=x,corthresh=corthresh,id_mapping_mat=id_mapping_mat,numcomps=numcomps))

}
