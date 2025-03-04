import { Injectable } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { GonService } from 'core-app/core/gon/gon.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

export interface IFCPermissionMap {
  manage_ifc_models:boolean;
  manage_bcf:boolean;
}

export interface IfcProjectDefinition {
  name:string;
  id:string;
}

export interface IfcModelDefinition {
  name:string;
  id:number;
  default:boolean;
}

export interface IFCGonDefinition {
  models:IfcModelDefinition[];
  shown_models:number[];
  projects:IfcProjectDefinition[];
  xkt_attachment_ids:{ [id:number]:number };
  permissions:IFCPermissionMap;
}

@Injectable()
export class IfcModelsDataService {
  constructor(
    readonly paths:PathHelperService,
    readonly currentProjectService:CurrentProjectService,
    readonly gon:GonService,
  ) { }

  public get models():IfcModelDefinition[] {
    return this.gonIFC.models;
  }

  public get projects():IfcProjectDefinition[] {
    return this.gonIFC.projects;
  }

  public get shownModels():number[] {
    return this.gonIFC.shown_models;
  }

  public isSingleModel() {
    return this.shownModels.length === 1;
  }

  public isDefaults():boolean {
    return !this
      .models
      .find((item) => item.default && this.shownModels.indexOf(item.id) === -1);
  }

  public get manageIFCPath() {
    return this.paths.ifcModelsPath(this.currentProjectService.identifier!);
  }

  public allowed(permission:keyof IFCPermissionMap):boolean {
    return !!this.gonIFC.permissions[permission];
  }

  private get gonIFC():IFCGonDefinition {
    return (this.gon.get('ifc_models') as IFCGonDefinition);
  }
}
